# class to drive codegen'd XLS verilog modules
# cocotb
import cocotb
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.handle import SimHandleBase, RealObject
from cocotb_bus.drivers import BusDriver
from cocotb_bus.monitors import BusMonitor
from cocotb.triggers import Trigger, ReadOnly, RisingEdge, ClockCycles, ReadWrite

# python
import os, sys, logging
from itertools import chain
from typing import Optional, Callable, Awaitable, cast, Coroutine

class ProcMonitor(BusMonitor):
    # doesnt assert ready, just passively monitors
    def __init__(self, dut: SimHandleBase, clock: RealObject, signals: list):
        self._signals = signals
        BusMonitor.__init__(self, dut, "", clock)

    def _grab_data(self) -> dict:
        retdict = {}
        for signal in self._signals:
            if getattr(self.bus, f"{signal}_vld").value == 1:
                retdict[signal] = getattr(self.bus, signal).value
        return retdict

    async def _monitor_recv(self):
        while True:
            await RisingEdge(self.clock)
            await ReadOnly()
            self._recv(self._grab_data())



class ProcDriver(BusDriver):
    def __init__(self, dut: SimHandleBase, clock: RealObject, signals: list):
        self._signals = signals
        BusDriver.__init__(self, dut, "", clock=clock)
        self.clock = clock
        for signal in self._signals:
            getattr(self.bus, signal).value = 0

    async def _driver_send(self, transaction: dict, sync=True):
        """
            Only send the non _vld and non_rdy signals, this will take care of the rest.
            Assumes:
                - starting on RisingEdge
            Does the following:
                1) Sets signals and valid to 1 (again remember we are assuming starting on RisingEdge)
                2) Waits for all the signals to be ready
                3) Then sets valid to 0
        """
        for signal, value in transaction.items():
            getattr(self.bus, signal).value = value
            getattr(self.bus, f"{signal}_vld").value = 1
        ready_signals = [f"{signal}_rdy" for signal in transaction.keys()]
        await RisingEdge(self.clock)
        # await ReadWrite() # <-- for some reason adding ReadWrite() here makes it break, figure out later ig
        while not all([getattr(self.bus, signal).value == 1 for signal in ready_signals]):
            await RisingEdge(self.clock)
        for signal, value in transaction.items():
            getattr(self.bus, f"{signal}_vld").value = 0

    def extend(self, input: list):
        for transaction in input:
            self.append(transaction)

class ProcTester:
    def __init__(self, dut_entity: SimHandleBase, clock: RealObject, reset: RealObject, input_signals: list, output_signals: Optional[list] = None):
        self.dut = dut_entity
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        # Create a scoreboard on the stream_out bus
        self.expected_output = [] #contains list of expected outputs (Growing)
        self.clock = clock
        self.cycle_count = 0
        self.reset = reset
        # although the ready signal is actualy an output, it doesnt matter as the ProcDriver will ensure it doesnt write to it
        real_input_signals = list(chain.from_iterable((signal, f"{signal}_vld", f"{signal}_rdy") for signal in input_signals))
        real_output_signals = list(chain.from_iterable((signal, f"{signal}_vld", f"{signal}_rdy") for signal in output_signals))
        self.input_driver = ProcDriver(dut=dut_entity, clock=clock, signals=real_input_signals)
    async def start(self, *coroutines: Callable[..., Awaitable[int]], reset = False, coroutine_kwargs: list[dict] = None) -> None:
        # dont support models for now
        async def cycle_counter():
            while True:
                await RisingEdge(self.dut.clk)
                self.cycle_count += 1
        for i, routine in enumerate(coroutines):
            if coroutine_kwargs is not None:
                cocotb.start_soon(cast(Coroutine[Trigger, None, int], routine(self.dut, **coroutine_kwargs[i])))
            else:
                cocotb.start_soon(routine(self.dut))
        cocotb.start_soon(Clock(self.clock, 10, units="ns").start()) # same clock as input monitor, defaults to 10ns
        cocotb.start_soon(cycle_counter())
        await RisingEdge(self.dut.clk)
        if reset:
            self.reset.value = 1
            await ClockCycles(self.dut.clk, 2)
            self.reset.value = 0
            await ClockCycles(self.dut.clk, 2)

def runner(basepath: str, files: list, toplevel_module_name: str, test_module_name: str):
    """Simulate the counter using the Python runner."""
    if (not os.path.isdir("../hdl") or not os.path.basename(os.getcwd()) == "sim"):
        print("Please run this in the /sim folder")
        return
    sim ="verilator"
    sys.path.append(f"{basepath}/sim/model")
    sources = [f"{basepath}/hdl/{source}" for source in files]
    build_test_args = ["-Wall", "--trace", "--trace-structs", "-O0", "-DSIMULATION"]# -O0 will keep all internal signals
    parameters = {}
    sys.path.append(f"{basepath}/sim")
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=toplevel_module_name,
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel=toplevel_module_name,
        test_module=test_module_name,
        test_args=run_test_args,
        waves=True
    )