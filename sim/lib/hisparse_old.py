# old drivers for hisparse actual version

import cocotb
from cocotb.triggers import RisingEdge, ReadWrite, ReadOnly
from cocotb.handle import SimHandleBase, BinaryValue
from typing import Tuple
from lib import hbm_channel


async def driver_core_read_write_old(dut: SimHandleBase, addr_signal_name: str) -> bool:
    await RisingEdge(dut.clk)
    await ReadWrite()
    if getattr(dut, f"{addr_signal_name}_vld").value == 1:
        return True
    else:
        return False

async def driver_core_read_write_worker_old(dut: SimHandleBase, latency: int, addr_signal_name: str, dout_signal_name: str) -> Tuple[bool, int, int]:
    getattr(dut, f"{addr_signal_name}_rdy").value = 1
    addr = getattr(dut, f"{addr_signal_name}").value
    read_req = hex(addr)[2:][0] == "8"
    write_req = hex(addr)[2:][0] == "4"
    dout = 0
    if write_req:
        while not getattr(dut, f"{dout_signal_name}_vld").value == 1:
            await RisingEdge(dut.clk)
            await ReadWrite()
            getattr(dut, f"{addr_signal_name}_rdy").value = 0
        getattr(dut, f"{dout_signal_name}_rdy").value = 1
        dout = getattr(dut, f"{dout_signal_name}").value
        await RisingEdge(dut.clk)
        await ReadWrite()
        getattr(dut, f"{addr_signal_name}_rdy").value = 0
        getattr(dut, f"{dout_signal_name}_rdy").value = 0
    elif read_req:
        await RisingEdge(dut.clk)
        await ReadWrite()
        getattr(dut, f"{addr_signal_name}_rdy").value = 0
    else:
        raise Exception("Unknown request")
    for _ in range(latency - 1):
        await RisingEdge(dut.clk)
    return write_req, addr, dout