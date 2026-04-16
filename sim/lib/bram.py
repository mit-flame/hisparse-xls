import cocotb
from cocotb.triggers import RisingEdge, ReadWrite, ReadOnly
from cocotb.handle import SimHandleBase, BinaryValue
from typing import Tuple

async def bram_worker(dut: SimHandleBase, latency: int, addr_signal_name: str, din_signal_name: str, wea_signal_name: str, enable_signal_name: str) -> Tuple[BinaryValue]:
    addr = getattr(dut, f"{addr_signal_name}").value
    din = getattr(dut, f"{din_signal_name}").value
    wea = getattr(dut, f"{wea_signal_name}").value
    en = getattr(dut, f"{enable_signal_name}").value
    for _ in range(latency - 1):
        await RisingEdge(dut.clk)
        await ReadOnly()
    return addr, din, wea, en

async def bram_port_driver(dut: SimHandleBase, latency: int, base_name: str, backing_memory: list):
    async def worker():
        addr, din, wea, en = await bram_worker(dut, latency, f"{base_name}_addr", f"{base_name}_din", f"{base_name}_wea", f"{base_name}_enable")
        await RisingEdge(dut.clk)
        await ReadWrite()
        addr = int(addr)
        if en:
            outp = backing_memory[addr]
            if wea:
                # print(f"{wea} {base_name} is writing {din} at addr {addr}")
                backing_memory[addr] = din
            getattr(dut, f"{base_name}_dout").value = outp
    while True:
        await RisingEdge(dut.clk)
        await ReadOnly()
        cocotb.start_soon(worker())