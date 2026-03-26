# driver coroutines for hisparse modules
# readys are combinational 
import cocotb
from cocotb.triggers import RisingEdge, ReadWrite
from cocotb.handle import SimHandleBase, BinaryValue
from typing import Tuple
from lib import hbm_channel

async def driver_core_read(dut: SimHandleBase, addr_signal_name: str) -> bool:
    await RisingEdge(dut.clk)
    await ReadWrite()
    if getattr(dut, f"{addr_signal_name}_vld").value == 1:
        return True
    else:
        return False
    
async def driver_core_read_worker(dut: SimHandleBase, latency: int, addr_signal_name: str) -> BinaryValue:
    getattr(dut, f"{addr_signal_name}_rdy").value = 1
    addr = getattr(dut, f"{addr_signal_name}").value
    await RisingEdge(dut.clk)
    await ReadWrite()
    getattr(dut, f"{addr_signal_name}_rdy").value = 0
    for _ in range(latency - 1):
        await RisingEdge(dut.clk)
    return addr

async def driver_core_read_write(dut: SimHandleBase, addr_signal_name: str) -> bool:
    await RisingEdge(dut.clk)
    await ReadWrite()
    if getattr(dut, f"{addr_signal_name}_vld").value == 1:
        return True
    else:
        return False

async def driver_core_read_write_worker(dut: SimHandleBase, latency: int, addr_signal_name: str, dout_signal_name: str) -> Tuple[bool, int, int]:
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
    
async def matrix_loader_driver(dut: SimHandleBase, matrix_fp: str, hbm_chan: int, latency: int = 2, num_streams: int = 1):
    total_hbm = hbm_channel.raw_to_cpsr_hbmchannel(matrix_fp, "+1", "#", 4, 4, 2, 1, True)
    mem = hbm_channel.HBM_CHAN(total_hbm=total_hbm, chan=hbm_chan, num_streams=num_streams)
    ALL_ONES = 2**32 - 1
    async def matrix_loader_worker():
        addr = await driver_core_read_worker(dut=dut, latency=latency, addr_signal_name="t__payload_type_one_index")
        addr = int(addr)
        packed_pld = mem[addr]
        packed_pld_str = ""
        for stream in reversed(packed_pld):
            if type(stream[0]) == str:
                if "+" in stream[0]: # next row marker
                    packed_pld_str += f"{ALL_ONES:0{8}x}" + f"{int(stream[0][1:]):0{8}x}"
                else: # padding
                    packed_pld_str += f"{0:0{8}x}" + f"{0:0{8}x}"
            else:
                packed_pld_str += f"{stream[1]:0{8}x}" + f"{stream[0]:0{8}x}"
        # print(f"running ml {addr} {packed_pld_str}")
        dut.t__payload_type_one.value = int(packed_pld_str, 16)
        dut.t__payload_type_one_vld.value = 1
        await RisingEdge(dut.clk)
        dut.t__payload_type_one.value = 0
        dut.t__payload_type_one_vld.value = 0

    while True:
        ok = await driver_core_read(dut=dut, addr_signal_name="t__payload_type_one_index")
        if ok:
            cocotb.start_soon(matrix_loader_worker())
            
async def vector_loader_driver(dut, mem: list[int], latency: int = 2, num_streams: int = 1):
    async def vector_loader_worker():
        addr = await driver_core_read_worker(dut=dut, latency=latency, addr_signal_name="t__hbm_vector_addr")
        addr = int(addr)
        packed_pld_str = ""
        for stream in range(num_streams):
            packed_pld_str += f"{mem[addr*num_streams + stream]:0{8}x}"
        # print(f"running vl {addr} {packed_pld_str}")
        dut.t__hbm_vector_payload.value = int(packed_pld_str, 16)
        dut.t__hbm_vector_payload_vld.value = 1
        await RisingEdge(dut.clk)
        dut.t__hbm_vector_payload.value = 0
        dut.t__hbm_vector_payload_vld.value = 0
    while True:
        ok = await driver_core_read(dut=dut, addr_signal_name="t__hbm_vector_addr")
        if ok:
            cocotb.start_soon(vector_loader_worker())            

async def vecbuf_driver(dut, vecbuf_name: str, latency: int = 2, banksize: int = 4):
    BANK = [0]*banksize
    async def vecbuf_driver_worker():
        write_req, addr, latched_dout = await driver_core_read_write_worker(dut=dut, addr_signal_name=f"{vecbuf_name}_t__vecbuf_bank_addr", dout_signal_name=f"{vecbuf_name}_t__vecbuf_dout", latency=latency)
        real_addr = int(hex(addr)[3:],16)
        # print(f"running vau with write req: {write_req} addr {addr} val {latched_dout}")
        if write_req:
            BANK[real_addr] = latched_dout
            # print(f"{vecbuf_name} wrote {int(latched_dout)} into bank addr {real_addr}")
        else:
            # print(f"{vecbuf_name} reading bank addr {real_addr} with val {int(BANK[real_addr])}")
            getattr(dut, f"{vecbuf_name}_t__vecbuf_din").value = BANK[real_addr]
            getattr(dut, f"{vecbuf_name}_t__vecbuf_din_vld").value = 1
            await RisingEdge(dut.clk)
            getattr(dut, f"{vecbuf_name}_t__vecbuf_din").value = 0
            getattr(dut, f"{vecbuf_name}_t__vecbuf_din_vld").value = 0
    while True:
        ok = await driver_core_read_write(dut=dut, addr_signal_name=f"{vecbuf_name}_t__vecbuf_bank_addr")
        if ok:
            cocotb.start_soon(vecbuf_driver_worker())

async def pe_driver(dut, pe_name: str, latency: int = 2, banksize: int = 4):
    BANK = [0]*banksize
    async def pe_driver_worker():
        write_req, addr, latched_dout = await driver_core_read_write_worker(dut=dut, addr_signal_name=f"{pe_name}_t__vecbuf_bank_addr", dout_signal_name=f"{pe_name}_t__vecbuf_bank_dout", latency=latency)
        real_addr = int(hex(addr)[3:],16)
        if write_req:
            BANK[real_addr] = latched_dout
            # print(f"{pe_name} wrote {int(latched_dout)} into bank addr {real_addr}")
        else:
            # print(f"{pe_name} reading bank addr {real_addr} with val {int(BANK[real_addr])}")
            getattr(dut, f"{pe_name}_t__vecbuf_bank_din").value = BANK[real_addr]
            getattr(dut, f"{pe_name}_t__vecbuf_bank_din_vld").value = 1
            await RisingEdge(dut.clk)
            getattr(dut, f"{pe_name}_t__vecbuf_bank_din").value = 0
            getattr(dut, f"{pe_name}_t__vecbuf_bank_din_vld").value = 0
    while True:
        ok = await driver_core_read_write(dut=dut, addr_signal_name=f"{pe_name}_t__vecbuf_bank_addr")
        if ok:
            cocotb.start_soon(pe_driver_worker())