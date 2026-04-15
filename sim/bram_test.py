import os

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, ReadWrite, ReadOnly

from lib.xlstools import runner

# tests refer to a 2 cycle latency bram

@cocotb.test()
async def no_backpressure(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.reset.value = 1
    await ClockCycles(dut.clk, 2)
    dut.downstream_ready.value = 1
    dut.reset.value = 0
    dut.info.value = 1
    dut.info_vld.value = 1
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 2
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 3
    dut.dout.value = 1
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 4
    dut.dout.value = 2
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 5
    dut.dout.value = 3
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info_vld.value = 0
    dut.dout.value = 4
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.dout.value = 5
    await RisingEdge(dut.clk)
    await ReadWrite()
    await RisingEdge(dut.clk)
    await ReadWrite()


# full backpressure implies the skid buffer filled up completely
@cocotb.test()
async def full_backpressure(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.reset.value = 1
    await ClockCycles(dut.clk, 2)
    dut.downstream_ready.value = 1
    dut.reset.value = 0
    dut.info.value = 1
    dut.info_vld.value = 1
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 2
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 3
    dut.dout.value = 1
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 4
    dut.dout.value = 2
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 5
    dut.dout.value = 3
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.dout.value = 4
    dut.info.value = 6
    dut.downstream_ready.value = 0
    await ReadOnly()
    assert dut.upstream_ready.value == 0
    print(f"is it ready (shouldnt be) {dut.upstream_ready.value}")
    await RisingEdge(dut.clk)
    await ReadWrite()
    # no info change because upstream should have been dereadied last cycle so there wasnt a transition
    dut.dout.value = 5
    await RisingEdge(dut.clk)
    await ReadWrite() # exactly 2 cycles to fill up the skid buffer
    dut.dout.value = 6
    # should be a long enough time to simulate long backpressure, now back up and flush
    dut.downstream_ready.value = 1
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 7
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 8
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 9
    dut.dout.value = 7
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info_vld.value = 0 # end of all valid infos
    dut.dout.value = 8
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.dout.value = 9
    await RisingEdge(dut.clk)
    await ReadWrite()
    await RisingEdge(dut.clk)
    await ReadWrite()
    await RisingEdge(dut.clk)
    await ReadWrite()

# partial backpressure implies the skid buffer filled up partially
@cocotb.test()
async def partial_backpressure(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.reset.value = 1
    await ClockCycles(dut.clk, 2)
    dut.downstream_ready.value = 1
    dut.reset.value = 0
    dut.info.value = 1
    dut.info_vld.value = 1
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 2
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 3
    dut.dout.value = 1
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 4
    dut.dout.value = 2
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 5
    dut.dout.value = 3
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.dout.value = 4
    dut.info.value = 6
    dut.downstream_ready.value = 0
    await ReadOnly()
    assert dut.upstream_ready.value == 0
    print(f"is it ready (shouldnt be) {dut.upstream_ready.value}")
    await RisingEdge(dut.clk)
    await ReadWrite()
    # no info change because upstream should have been dereadied last cycle so there wasnt a transition
    dut.dout.value = 5
    # should be a long enough time to simulate short backpressure, now back up and flush
    dut.downstream_ready.value = 1
    await RisingEdge(dut.clk)
    await ReadWrite() # exactly 1 cycle for partial fill
    dut.dout.value = 6
    dut.info_vld.value = 0 # set it to 0 since transaciton comleted
    await RisingEdge(dut.clk)
    await ReadWrite()
    await RisingEdge(dut.clk)
    await ReadWrite()
    await RisingEdge(dut.clk)
    await ReadWrite()
    await RisingEdge(dut.clk)
    await ReadWrite()
    await RisingEdge(dut.clk)
    await ReadWrite()
    await RisingEdge(dut.clk)
    await ReadWrite()



# partial backpressure implies the skid buffer filled up partially
@cocotb.test()
async def partial_backpressure_2(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.reset.value = 1
    await ClockCycles(dut.clk, 2)
    dut.downstream_ready.value = 1
    dut.reset.value = 0
    dut.info.value = 1
    dut.info_vld.value = 1
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 2
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 3
    dut.dout.value = 1
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 4
    dut.dout.value = 2
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 5
    dut.dout.value = 3
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.dout.value = 4
    dut.info.value = 6
    dut.downstream_ready.value = 0
    await ReadOnly()
    assert dut.upstream_ready.value == 0
    print(f"is it ready (shouldnt be) {dut.upstream_ready.value}")
    await RisingEdge(dut.clk)
    await ReadWrite()
    # no info change because upstream should have been dereadied last cycle so there wasnt a transition
    dut.dout.value = 5
    # should be a long enough time to simulate short backpressure, now back up and flush
    dut.downstream_ready.value = 1
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.dout.value = 6
    dut.info.value = 7
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 8
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info.value = 9
    dut.dout.value = 7
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.info_vld.value = 0 # end of all valid infos
    dut.dout.value = 8
    await RisingEdge(dut.clk)
    await ReadWrite()
    dut.dout.value = 9
    await RisingEdge(dut.clk)
    await ReadWrite()
    await RisingEdge(dut.clk)
    await ReadWrite()
    await RisingEdge(dut.clk)
    await ReadWrite()

if __name__ == "__main__":
    runner(basepath=os.path.dirname(os.getcwd()),files=[
        "single_cluster_bram_info_pipeline.sv"
        ], toplevel_module_name="single_cluster_bram_info_pipeline", test_module_name=os.path.basename(__file__)[:-3])