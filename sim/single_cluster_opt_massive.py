import os, json

import cocotb
from cocotb.triggers import RisingEdge

from lib.xlstools import ProcTester, runner
from lib import hisparse

NUM_STREAMS = 2
VB_BANK_SIZE = 4
OB_BANK_SIZE = 4

def calculate_reference(matrix_fp: str, vec: list[int]):
    res = [0]*len(vec)
    with open(matrix_fp) as file:
        mtrx = json.load(file)["raw"]
        for r, row in enumerate(mtrx):
            for c, val in enumerate(row):
                res[r] += vec[c]*val
    return res

@cocotb.test()
async def test_single_cluster_sparse(dut):
    tester = ProcTester(dut_entity=dut, clock=dut.clk, reset=dut.rst,
                input_signals=[
                    # ml
                    "t__unified_pld",
                    "t__cur_row_partition",
                    "t__num_col_partitions",
                    "t__tot_num_partitions",
                    # vl
                    "t__hbm_vector_payload",
                    "t__num_matrix_cols",
                    # vau 0 and 1
                    "vecbuf0_t__num_col_partitions",
                    "vecbuf0_t__streaming_pld",
                    "vecbuf1_t__num_col_partitions",
                    "vecbuf1_t__streaming_pld",
                    # pe 0 and 1
                    "pe0_t__num_rows_updated",
                    "pe0_t__stream_id",
                    "pe0_t__unified_pld",
                    "pe1_t__num_rows_updated",
                    "pe1_t__stream_id",
                    "pe1_t__unified_pld",
                    # kmerger
                    "kmerger_t__current_row_partition",
                    "kmerger_t__num_hbm_channels_each_kernel"      
                ],
                output_signals=[
                    # ml
                    "t__unified_addr",
                    # vl
                    "t__hbm_vector_addr",
                    # vau 0 and 1
                    "vecbuf0_t__unified_addr",
                    "vecbuf1_t__unified_addr",
                    # pe 0 and 1
                    "pe0_t__unified_addr",
                    "pe0_t__accumulation_addr",
                    "pe1_t__unified_addr",
                    "pe1_t__accumulation_addr",
                    # kmerger
                    "kmerger_t__hbm_vector_addr",
                    "kmerger_t__hbm_vector_payload"
                    ])
    mlkwargs = {"hbm_chan": 0, "matrix_fp": "/home/ayana/hisparse-xls/data/spmv3.json", "latency": 1, "num_streams": NUM_STREAMS, "addr_sig": "t__unified_addr", "pld_sig": "t__unified_pld", "out_vec_buf_len": NUM_STREAMS*OB_BANK_SIZE, "in_vec_buf_len": NUM_STREAMS*VB_BANK_SIZE}    
    vlkwargs = {"mem": list(range(32)), "latency": 1, "num_streams": NUM_STREAMS, "addr_sig": "t__hbm_vector_addr", "pld_sig": "t__hbm_vector_payload"}
    vb0kwargs = {"vecbuf_name": "vecbuf0", "latency": 1, "banksize": VB_BANK_SIZE, "addr_sig": "t__unified_addr", "pld_sig": "t__streaming_pld"}
    vb1kwargs = {"vecbuf_name": "vecbuf1", "latency": 1, "banksize": VB_BANK_SIZE, "addr_sig": "t__unified_addr", "pld_sig": "t__streaming_pld"}
    pe0bank = [0]*OB_BANK_SIZE
    pe1bank = [0]*OB_BANK_SIZE
    pe0sendkwargs = {"pe_name": "pe0", "latency": 1, "shared_bank": pe0bank, "addr_sig": "t__unified_addr", "pld_sig": "t__unified_pld"}
    pe0recvkwargs = {"pe_name": "pe0", "latency": 1, "shared_bank": pe0bank, "addr_sig": "t__accumulation_addr", "pld_sig": "t__dummy_accumulate_pld"} # purely writes for accumulation addr, dummy pld to satisfy driver
    pe1sendkwargs = {"pe_name": "pe1", "latency": 1, "shared_bank": pe1bank, "addr_sig": "t__unified_addr", "pld_sig": "t__unified_pld"}
    pe1recvkwargs = {"pe_name": "pe1", "latency": 1, "shared_bank": pe1bank, "addr_sig": "t__accumulation_addr", "pld_sig": "t__dummy_accumulate_pld"} # purely writes for accumulation addr, dummy pld to satisfy driver
    dut.kmerger_t__hbm_vector_addr_rdy.value = 1
    dut.kmerger_t__hbm_vector_payload_rdy.value = 1
    await tester.start(
        hisparse.matrix_loader_split_driver, hisparse.vector_loader_driver, hisparse.vecbuf_driver, hisparse.vecbuf_driver, hisparse.pe_driver, hisparse.pe_driver, hisparse.pe_driver, hisparse.pe_driver,
        reset=True, 
        coroutine_kwargs=[mlkwargs, vlkwargs, vb0kwargs, vb1kwargs, pe0sendkwargs, pe0recvkwargs, pe1sendkwargs, pe1recvkwargs]
    )
    output = []
    for row_part in range(4):
        tester.input_driver.extend([{
            "t__cur_row_partition": row_part,
            "t__num_col_partitions": 4,
            "t__tot_num_partitions": 16,
            "t__num_matrix_cols": 32,
            "kmerger_t__current_row_partition":row_part,
            "kmerger_t__num_hbm_channels_each_kernel":1
            }])
        tester.input_driver.extend([{"vecbuf0_t__num_col_partitions":4,
                                    "vecbuf1_t__num_col_partitions":4,
                                    "pe0_t__num_rows_updated":OB_BANK_SIZE,
                                    "pe0_t__stream_id":0,
                                    "pe1_t__num_rows_updated":OB_BANK_SIZE,
                                    "pe1_t__stream_id":1,
                                    }])
        for _ in range(4):
            await RisingEdge(dut.kmerger_t__hbm_vector_addr_vld)
            addr = int(dut.kmerger_t__hbm_vector_addr.value)
            if dut.kmerger_t__hbm_vector_payload_vld.value != 1:
                await RisingEdge(dut.kmerger_t__hbm_vector_payload_vld)
            payload = str(dut.kmerger_t__hbm_vector_payload.value)
            payload = [int(payload[len(payload)//2:], 2),int(payload[:len(payload)//2], 2)] 
            print(f"Output: packed_payload[{addr}] = {payload}")
            output.extend(payload)
    print(f"Test took {tester.cycle_count} cycles")
    ref = calculate_reference(matrix_fp="/home/ayana/hisparse-xls/data/spmv3.json", vec=list(range(32)))
    print(f"reference {ref}")
    assert all([ref[i] == output[i] for i in range(len(ref))]), "SpMV output did not match"

if __name__ == "__main__":
    runner(basepath=os.path.dirname(os.getcwd()),files=[
        "single_cluster_opt.sv",
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
        ], toplevel_module_name="single_cluster_opt", test_module_name=os.path.basename(__file__)[:-3])