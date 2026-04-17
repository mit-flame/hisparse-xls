import os, json

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles

from lib.xlstools import ProcTester, runner
from lib import bram, hbm_channel

def calculate_reference(matrix_fp: str, vec: list[int]):
    res = [0]*len(vec)
    with open(matrix_fp) as file:
        mtrx = json.load(file)["raw"]
        for r, row in enumerate(mtrx):
            for c, val in enumerate(row):
                res[r] += vec[c]*val
    return res

class ListWrapper:
    def __init__(self, list, wrapper_func):
        self.list = list
        self.wrapper_func = wrapper_func
    def __getitem__(self, ind: int):
        return (self.wrapper_func(self.list, ind))

@cocotb.test()
async def test_single_cluster_sparse(dut):
    tester = ProcTester(dut_entity=dut, clock=dut.clk, reset=dut.reset,
                # this version is not driving anything, so no input signals
                # and we will just sample the output signals ourselves
                input_signals=[  
                ],
                output_signals=[
                ])
    total_hbm = hbm_channel.raw_to_cpsr_hbmchannel("/home/ayana/hisparse-xls/data/spmv1.json", "+1", "#", 4, 4, 2, 1, True)
    mlbramkwargs = {"latency": 2, "base_name": "ml_bram", "backing_memory": ListWrapper(hbm_channel.HBM_CHAN(total_hbm=total_hbm, chan=0, num_streams=2), hbm_channel.grab_binary_value)}
    vlbramkwargs = {"latency": 2, "base_name": "vl_bram", "backing_memory": ListWrapper(list(range(8)), hbm_channel.vec_int_func)}
    vau0bramkwargs = {"latency": 2, "base_name": "vau0_bram", "backing_memory": [0]*2}
    vau1bramkwargs = {"latency": 2, "base_name": "vau1_bram", "backing_memory": [0]*2}
    pe0bank = [0]*2
    pe1bank = [0]*2
    pe0sbramkwargs = {"latency": 2, "base_name": "pe0s_bram", "backing_memory": pe0bank}
    pe0abramkwargs = {"latency": 2, "base_name": "pe0a_bram", "backing_memory": pe0bank}
    pe1sbramkwargs = {"latency": 2, "base_name": "pe1s_bram", "backing_memory": pe1bank}
    pe1abramkwargs = {"latency": 2, "base_name": "pe1a_bram", "backing_memory": pe1bank}
    await tester.start(
        bram.bram_port_driver, bram.bram_port_driver, bram.bram_port_driver, bram.bram_port_driver, bram.bram_port_driver, bram.bram_port_driver, bram.bram_port_driver, bram.bram_port_driver,
        reset=True, 
        coroutine_kwargs=[mlbramkwargs, vlbramkwargs, vau0bramkwargs, vau1bramkwargs, pe0sbramkwargs, pe0abramkwargs, pe1sbramkwargs, pe1abramkwargs]
    )
    await RisingEdge(dut.finished)
    await ClockCycles(dut.clk, 20)
    print(f"Test took {int(dut.num_cycles)} cycles")
    print([int(x) for x in pe0bank], [int(x) for x  in pe1bank])
    # ref = calculate_reference(matrix_fp="/home/ayana/hisparse-xls/data/spmv1.json", vec=list(range(8)))
    # print(f"reference {ref}")
    # assert all([ref[i] == output[i] for i in range(len(ref))]), "SpMV output did not match"

if __name__ == "__main__":
    runner(basepath=os.path.dirname(os.getcwd()),files=[
        "single_cluster_opt.sv",
        "single_cluster_opt_driver.sv",
        "single_cluster_bram_info_pipeline.sv",
        "single_cluster_opt_fpga_top.sv",
        "__t__arbiter_wrapper_0_next.sv",
        "__t__matrix_loader_recv_0_next.sv",
        "__t__matrix_loader_send_0_next.sv",
        "__t__matrix_loader_addr_arbiter_0_next.sv",
        "__t__matrix_loader_pld_arbiter_0_next.sv",
        "__t__sod_syncer_0_next.sv",
        "__t__eos_syncer_0_next.sv",
        "__t__shuffler_core_0_next.sv",
        "__t__vba_recv_0_next.sv",
        "__t__vba_send_0_next.sv",
        "__t__vba_addr_arbiter_0_next.sv",
        "__t__vector_loader_0_next.sv",
        "__t__vector_unpacker_0_next.sv",
        "__t__pe_addr_arbiter_0_next.sv",
        "__t__pe_recv_0_next.sv",
        "__t__pe_send_0_next.sv",
        "__t__cluster_packer_0_next.sv",
        "__t__clusters_results_merger_0_next.sv",
        "__t__kernels_results_merger_0_next.sv"
        ], toplevel_module_name="single_cluster_opt_fpga_top", test_module_name=os.path.basename(__file__)[:-3])