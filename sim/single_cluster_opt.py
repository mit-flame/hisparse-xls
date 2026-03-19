import os

import cocotb
from cocotb.triggers import RisingEdge

from lib.xlstools import ProcTester, runner
from lib import hisparse

@cocotb.test()
async def test_single_cluster(dut):
    tester = ProcTester(dut_entity=dut, clock=dut.clk, reset=dut.rst,
                input_signals=[
                    # ml
                    "t__metadata_payload",
                    "t__streaming_payload_one",
                    "t__cur_row_partition",
                    "t__num_col_partitions",
                    "t__tot_num_partitions",
                    # vl
                    "t__hbm_vector_payload",
                    "t__num_matrix_cols",
                    # vau 0 and 1
                    "vecbuf0_t__num_col_partitions",
                    "vecbuf0_t__vecbuf_din",
                    "vecbuf1_t__num_col_partitions",
                    "vecbuf1_t__vecbuf_din",
                    # pe 0 and 1
                    "pe0_t__num_rows_updated",
                    "pe0_t__stream_id",
                    "pe0_t__vecbuf_bank_din",
                    "pe1_t__num_rows_updated",
                    "pe1_t__stream_id",
                    "pe1_t__vecbuf_bank_din",
                    # kmerger
                    "kmerger_t__current_row_partition",
                    "kmerger_t__num_hbm_channels_each_kernel"      
                ],
                output_signals=[
                    # ml
                    "t__metadata_addr",
                    "t__streaming_addr",
                    # vl
                    "t__hbm_vector_addr",
                    # vau 0 and 1
                    "vecbuf0_t__vecbuf_bank_addr",
                    "vecbuf0_t__vecbuf_dout",
                    "vecbuf1_t__vecbuf_bank_addr",
                    "vecbuf1_t__vecbuf_dout",
                    # pe 0 and 1
                    "pe0_t__vecbuf_bank_addr",
                    "pe0_t__vecbuf_bank_dout",
                    "pe1_t__vecbuf_bank_addr",
                    "pe1_t__vecbuf_bank_dout",
                    # kmerger
                    "kmerger_t__hbm_vector_addr",
                    "kmerger_t__hbm_vector_payload"
                    ])
    ml_metadata_kwargs = {"hbm_chan": 0, "matrix_fp": "/home/ayana/hisparse-xls/data/spmv1.json", "latency": 1, "num_streams": 2, "addr_sig": "t__metadata_addr", "pld_sig": "t__metadata_payload"}
    ml_streaming_kwargs = {"hbm_chan": 0, "matrix_fp": "/home/ayana/hisparse-xls/data/spmv1.json", "latency": 1, "num_streams": 2, "addr_sig": "t__streaming_addr", "pld_sig": "t__streaming_payload_one"}    
    vlkwargs = {"mem": [0, 1, 2, 3, 4, 5, 6, 7], "latency": 1, "num_streams": 2, "addr_sig": "t__hbm_vector_addr", "pld_sig": "t__hbm_vector_payload"}
    vb0kwargs = {"vecbuf_name": "vecbuf0", "latency": 1, "banksize": 4}
    vb1kwargs = {"vecbuf_name": "vecbuf1", "latency": 1, "banksize": 4}
    pe0kwargs = {"pe_name": "pe0", "latency": 1, "banksize": 4}
    pe1kwargs = {"pe_name": "pe1", "latency": 1, "banksize": 4}
    dut.kmerger_t__hbm_vector_addr_rdy.value = 1
    dut.kmerger_t__hbm_vector_payload_rdy.value = 1
    await tester.start(
        hisparse.matrix_loader_regular_driver, hisparse.matrix_loader_split_driver, hisparse.vector_loader_driver, hisparse.vecbuf_driver, hisparse.vecbuf_driver, hisparse.pe_driver, hisparse.pe_driver,
        reset=True, 
        coroutine_kwargs=[ml_metadata_kwargs, ml_streaming_kwargs, vlkwargs, vb0kwargs, vb1kwargs, pe0kwargs, pe1kwargs]
    )
    for row_part in range(2):
        tester.input_driver.extend([{
            "t__cur_row_partition": row_part,
            "t__num_col_partitions": 2,
            "t__tot_num_partitions": 4,
            "t__num_matrix_cols": 8,
            "kmerger_t__current_row_partition":row_part,
            "kmerger_t__num_hbm_channels_each_kernel":1
            }])
        tester.input_driver.extend([{"vecbuf0_t__num_col_partitions":2,
                                    "vecbuf1_t__num_col_partitions":2,
                                    "pe0_t__num_rows_updated":2,
                                    "pe0_t__stream_id":0,
                                    "pe1_t__num_rows_updated":2,
                                    "pe1_t__stream_id":1,
                                    }])
        for _ in range(2):
            await RisingEdge(dut.kmerger_t__hbm_vector_addr_vld)
            addr = int(dut.kmerger_t__hbm_vector_addr.value)
            if dut.kmerger_t__hbm_vector_payload_vld.value != 1:
                await RisingEdge(dut.kmerger_t__hbm_vector_payload_vld)
            payload = str(dut.kmerger_t__hbm_vector_payload.value)
            payload = [int(payload[:len(payload)//2], 2),int(payload[len(payload)//2:], 2)] 
            print(f"Output: packed_payload[{addr}] = {payload}")
    print(f"Test took {tester.cycle_count} cycles")

if __name__ == "__main__":
    runner(basepath=os.path.dirname(os.getcwd()),files=[
        "single_cluster_opt.sv",
        "__t__arbiter_wrapper_0_next.sv",
        "__t__matrix_loader_recv_0_next.sv",
        "__t__matrix_loader_send_0_next.sv",
        "__t__shuffler_core_0_next.sv",
        "__t__vecbuf_access_unit_0_next.sv",
        "__t__vector_loader_0_next.sv",
        "__t__vector_unpacker_0_next.sv",
        "__t__processing_engine_0_next.sv",
        "__t__cluster_packer_0_next.sv",
        "__t__clusters_results_merger_0_next.sv",
        "__t__kernels_results_merger_0_next.sv"
        ], toplevel_module_name="single_cluster_opt", test_module_name=os.path.basename(__file__)[:-3])