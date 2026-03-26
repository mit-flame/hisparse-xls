# driver coroutines for hisparse opt modules
# readys are combinational 
import cocotb
from cocotb.triggers import RisingEdge, ReadWrite, ReadOnly
from cocotb.handle import SimHandleBase, BinaryValue
from typing import Tuple
from lib import hbm_channel

async def driver_core_read_combinational_ready(dut: SimHandleBase, addr_signal_name: str, pld_signal_name: str):
    while True:
        await RisingEdge(dut.clk)
        for _ in range(10): # arbitrary evaluation cycle waits to ensure value settle
            await ReadWrite()
        if getattr(dut, f"{pld_signal_name}_vld").value != 1 or getattr(dut, f"{pld_signal_name}_rdy").value == 1:
            getattr(dut, f"{addr_signal_name}_rdy").value = 1
        else:
            getattr(dut, f"{addr_signal_name}_rdy").value = 0

async def driver_core_read(dut: SimHandleBase, addr_signal_name: str) -> bool:
    await RisingEdge(dut.clk)
    await ReadOnly()
    if getattr(dut, f"{addr_signal_name}_vld").value == 1 and getattr(dut, f"{addr_signal_name}_rdy").value == 1: # is a transaction allowable?
        return True
    else:
        return False

async def driver_core_read_worker(dut: SimHandleBase, latency: int, addr_signal_name: str) -> BinaryValue:
    addr = getattr(dut, f"{addr_signal_name}").value
    for _ in range(latency - 1):
        # a ready deassertion mid latency == pausing of this loops progress
        while getattr(dut, f"{addr_signal_name}_rdy").value != 1:
            await RisingEdge(getattr(dut, f"{addr_signal_name}_rdy"))
            await ReadOnly()
        await RisingEdge(dut.clk)
        await ReadOnly()
    return addr

async def driver_core_read_write_combinational_ready(dut: SimHandleBase, addr_signal_name: str, pld_signal_name: str):
    while True:
        await RisingEdge(dut.clk)
        for _ in range(10): # arbitrary evaluation cycle waits to ensure value settle
            await ReadWrite()
        if getattr(dut, f"{pld_signal_name}_vld").value != 1 or getattr(dut, f"{pld_signal_name}_rdy").value == 1:
            getattr(dut, f"{addr_signal_name}_rdy").value = 1
        else:
            getattr(dut, f"{addr_signal_name}_rdy").value = 0

async def driver_core_read_write(dut: SimHandleBase, addr_signal_name: str) -> bool:
    await RisingEdge(dut.clk)
    await ReadOnly()
    if getattr(dut, f"{addr_signal_name}_vld").value == 1 and getattr(dut, f"{addr_signal_name}_rdy").value == 1: # is a transaction allowable?
        return True
    else:
        return False

async def driver_core_read_write_worker(dut: SimHandleBase, latency: int, addr_signal_name: str) -> Tuple[bool, int, int, int, int, int]:
    addr_raw = str(getattr(dut, f"{addr_signal_name}").value)
    write_req, commands, addr = int(addr_raw[0], 2) == 1, int(addr_raw[1:3], 2), int(addr_raw[3:32], 2)
    write_pld, matrix_pld, row_indx = int(addr_raw[32:64], 2), int(addr_raw[64:96], 2), int(addr_raw[96:128], 2)
    for _ in range(latency - 1):
        # a ready deassertion mid latency == pausing of this loops progress
        while getattr(dut, f"{addr_signal_name}_rdy").value != 1:
            await RisingEdge(getattr(dut, f"{addr_signal_name}_rdy"))
            await ReadOnly()
        await RisingEdge(dut.clk)
        await ReadOnly()
    return write_req, commands, addr, write_pld, matrix_pld, row_indx
    
async def matrix_loader_regular_driver(dut: SimHandleBase, matrix_fp: str, hbm_chan: int, addr_sig: str, pld_sig: str, latency: int = 2, num_streams: int = 1):
    total_hbm = hbm_channel.raw_to_cpsr_hbmchannel(matrix_fp, "+1", "#", 4, 4, 2, 1, True)
    mem = hbm_channel.HBM_CHAN(total_hbm=total_hbm, chan=hbm_chan, num_streams=num_streams)
    ALL_ONES = 2**32 - 1
    async def matrix_loader_worker():
        addr = await driver_core_read_worker(dut=dut, latency=latency, addr_signal_name=addr_sig)
        await RisingEdge(dut.clk)
        await ReadWrite()
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
        # print(f"running mlsend {addr} {packed_pld_str}")
        await ReadWrite() # to give this setting vld to 1 a higher priority than the subsequent setting vld to 0 (for II 1 scenarios), this additional ReadWrite() is necessary
        getattr(dut, f"{pld_sig}").value = int(packed_pld_str, 16)
        getattr(dut, f"{pld_sig}_vld").value = 1
        await ReadOnly()
        while getattr(dut, f"{pld_sig}_rdy").value != 1:
            await RisingEdge(getattr(dut, f"{pld_sig}_rdy"))
            await ReadOnly()
        await RisingEdge(dut.clk)
        await ReadWrite()
        getattr(dut, f"{pld_sig}").value = 0
        getattr(dut, f"{pld_sig}_vld").value = 0
    cocotb.start_soon(driver_core_read_combinational_ready(dut=dut, addr_signal_name=addr_sig, pld_signal_name=pld_sig))
    while True:
        ok = await driver_core_read(dut=dut, addr_signal_name=addr_sig)
        if ok:
            cocotb.start_soon(matrix_loader_worker())

async def matrix_loader_split_driver(dut: SimHandleBase, matrix_fp: str, hbm_chan: int, addr_sig: str, pld_sig: str, latency: int = 2, num_streams: int = 1):
    total_hbm = hbm_channel.raw_to_cpsr_hbmchannel(matrix_fp, "+1", "#", 4, 4, 2, 1, True)
    mem = hbm_channel.HBM_CHAN(total_hbm=total_hbm, chan=hbm_chan, num_streams=num_streams)
    ALL_ONES = 2**32 - 1
    async def matrix_loader_worker():
        addr_commands = await driver_core_read_worker(dut=dut, latency=latency, addr_signal_name=addr_sig)
        addr_commands = str(addr_commands)
        addr, metadata = int(addr_commands[:len(addr_commands)//2], 2), int(addr_commands[len(addr_commands)//2:], 2)
        await RisingEdge(dut.clk)
        await ReadWrite()
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
        packed_pld_str += f"{metadata:0{8}x}"
        # print(f"running mlrecv {addr_commands} {addr} {packed_pld_str}")
        await ReadWrite() # to give this setting vld to 1 a higher priority than the subsequent setting vld to 0 (for II 1 scenarios), this additional ReadWrite() is necessary
        getattr(dut, f"{pld_sig}").value = int(packed_pld_str, 16)
        getattr(dut, f"{pld_sig}_vld").value = 1
        await ReadOnly()
        while getattr(dut, f"{pld_sig}_rdy").value != 1:
            await RisingEdge(getattr(dut, f"{pld_sig}_rdy"))
            await ReadOnly()
        await RisingEdge(dut.clk)
        await ReadWrite()
        getattr(dut, f"{pld_sig}").value = 0
        getattr(dut, f"{pld_sig}_vld").value = 0
    cocotb.start_soon(driver_core_read_combinational_ready(dut=dut, addr_signal_name=addr_sig, pld_signal_name=pld_sig))
    while True:
        ok = await driver_core_read(dut=dut, addr_signal_name=addr_sig)
        if ok:
            cocotb.start_soon(matrix_loader_worker())
            
async def vector_loader_driver(dut, mem: list[int], addr_sig: str, pld_sig: str, latency: int = 2, num_streams: int = 1):
    async def vector_loader_worker():
        addr = await driver_core_read_worker(dut=dut, latency=latency, addr_signal_name=addr_sig)
        await RisingEdge(dut.clk)
        await ReadWrite()
        addr = int(addr)
        packed_pld_str = ""
        for stream in range(num_streams):
            packed_pld_str += f"{mem[addr*num_streams + stream]:0{8}x}"
        await ReadWrite() # to give this setting vld to 1 a higher priority than the subsequent setting vld to 0 (for II 1 scenarios), this additional ReadWrite() is necessary
        getattr(dut, f"{pld_sig}").value = int(packed_pld_str, 16)
        getattr(dut, f"{pld_sig}_vld").value = 1
        await ReadOnly()
        while getattr(dut, f"{pld_sig}_rdy").value != 1:
            await RisingEdge(getattr(dut, f"{pld_sig}_rdy"))
            await ReadOnly()
        await RisingEdge(dut.clk)
        await ReadWrite()
        getattr(dut, f"{pld_sig}").value = 0
        getattr(dut, f"{pld_sig}_vld").value = 0
    cocotb.start_soon(driver_core_read_combinational_ready(dut=dut, addr_signal_name=addr_sig, pld_signal_name=pld_sig))
    while True:
        ok = await driver_core_read(dut=dut, addr_signal_name=addr_sig)
        if ok:
            cocotb.start_soon(vector_loader_worker())            

async def vecbuf_driver(dut, vecbuf_name: str, addr_sig: str, pld_sig: str, latency: int = 2, banksize: int = 4):
    BANK = [0]*banksize
    async def vecbuf_driver_worker():
        write_req, commands, real_addr, write_pld, matrix_pld, row_indx = await driver_core_read_write_worker(dut=dut, addr_signal_name=f"{vecbuf_name}_{addr_sig}", latency=latency)
        # print(f"running vau {vecbuf_name} with write req: {write_req} {commands} {real_addr} {write_pld} {matrix_pld} {row_indx} raw {getattr(dut, f"{vecbuf_name}_{addr_sig}").value}")
        await RisingEdge(dut.clk)
        await ReadWrite()
        if write_req:
            BANK[real_addr] = write_pld
            # print(f"{vecbuf_name} wrote {int(write_pld)} into bank addr {real_addr}")
        else:
            await ReadWrite() # to give this setting vld to 1 a higher priority than the subsequent setting vld to 0 (for II 1 scenarios), this additional ReadWrite() is necessary
            # print(f"{vecbuf_name} reading bank addr {real_addr} with val {int(BANK[real_addr])} output str {f"{commands:0{2}b}" + f"{row_indx:0{30}b}" + f"{BANK[real_addr]:0{32}b}" + f"{matrix_pld:0{32}b}"}")
            getattr(dut, f"{vecbuf_name}_{pld_sig}").value = int(f"{commands:0{2}b}" + f"{row_indx:0{30}b}" + f"{BANK[real_addr]:0{32}b}" + f"{matrix_pld:0{32}b}", 2)
            getattr(dut, f"{vecbuf_name}_{pld_sig}_vld").value = 1
            await ReadOnly()
            while getattr(dut, f"{vecbuf_name}_{pld_sig}_rdy").value != 1:
                # print(f"{vecbuf_name} waiting {f"{commands:0{2}b}" + f"{row_indx:0{30}b}" + f"{BANK[real_addr]:0{32}b}" + f"{matrix_pld:0{32}b}"} {getattr(dut, f"{vecbuf_name}_{pld_sig}_vld").value}")
                await RisingEdge(dut.clk)
                await ReadOnly()
            # input()
            await RisingEdge(dut.clk)
            await ReadWrite()
            getattr(dut, f"{vecbuf_name}_{pld_sig}").value = 0
            getattr(dut, f"{vecbuf_name}_{pld_sig}_vld").value = 0
    cocotb.start_soon(driver_core_read_write_combinational_ready(dut=dut, addr_signal_name=f"{vecbuf_name}_{addr_sig}", pld_signal_name=f"{vecbuf_name}_{pld_sig}"))
    while True:
        ok = await driver_core_read_write(dut=dut, addr_signal_name=f"{vecbuf_name}_{addr_sig}")
        if ok:
            # print(f"{vecbuf_name} firing worker for addr {getattr(dut, f"{vecbuf_name}_{addr_sig}").value}")
            cocotb.start_soon(vecbuf_driver_worker())

async def pe_driver(dut, pe_name: str, addr_sig: str, pld_sig: str, shared_bank: list[int], latency: int = 2):
    async def pe_driver_worker():
        write_req, commands, real_addr, write_pld, matrix_val, vector_val = await driver_core_read_write_worker(dut=dut, addr_signal_name=f"{pe_name}_{addr_sig}", latency=latency)
        await RisingEdge(dut.clk)
        await ReadWrite()
        if write_req:
            shared_bank[real_addr] = write_pld
            # print(f"{pe_name} wrote {int(latched_dout)} into bank addr {real_addr}")
        else:
            await ReadWrite() # to give this setting vld to 1 a higher priority than the subsequent setting vld to 0 (for II 1 scenarios), this additional ReadWrite() is necessary
            # print(f"{pe_name} reading bank addr {real_addr} with val {int(BANK[real_addr])}")
            getattr(dut, f"{pe_name}_{pld_sig}").value = int(f"{commands:0{2}b}" + f"{real_addr:0{30}b}" + f"{matrix_val:0{32}b}" + f"{vector_val:0{32}b}" + f"{shared_bank[real_addr]:0{32}b}", 2)
            getattr(dut, f"{pe_name}_{pld_sig}_vld").value = 1
            await ReadOnly()
            while getattr(dut, f"{pe_name}_{pld_sig}_rdy").value != 1:
                await RisingEdge(dut.clk)
                await ReadOnly()
            await RisingEdge(dut.clk)
            await ReadWrite()
            getattr(dut, f"{pe_name}_{pld_sig}").value = 0
            getattr(dut, f"{pe_name}_{pld_sig}_vld").value = 0
    cocotb.start_soon(driver_core_read_write_combinational_ready(dut=dut, addr_signal_name=f"{pe_name}_{addr_sig}", pld_signal_name=f"{pe_name}_{pld_sig}"))
    while True:
        ok = await driver_core_read_write(dut=dut, addr_signal_name=f"{pe_name}_{addr_sig}")
        if ok:
            cocotb.start_soon(pe_driver_worker())