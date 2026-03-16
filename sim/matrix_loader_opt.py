# optimizing cycle performance of matrix loader

import os

import cocotb
from cocotb.triggers import ClockCycles

from lib.xlstools import ProcTester, runner
from lib import hisparse

@cocotb.test()
async def test_matrix_loader(dut):
    tester = ProcTester(dut_entity=dut, clock=dut.clk, reset=dut.rst,
                    input_signals=[
                        "t__metadata_payload",
                        "t__streaming_payload_one",
                        "t__cur_row_partition",
                        "t__num_col_partitions",
                        "t__tot_num_partitions"
                    ], 
                    output_signals=[
                        "t__metadata_addr",
                        "t__streaming_addr",
                        "t__multistream_payload_type_two__0",
                        "t__multistream_payload_type_two__1"
                    ])
    ml_metadata_kwargs = {"hbm_chan": 0, "matrix_fp": "/home/ayana/hisparse-xls/data/spmv1.json", "latency": 1, "num_streams": 2, "addr_sig": "t__metadata_addr", "pld_sig": "t__metadata_payload"}
    ml_streaming_kwargs = {"hbm_chan": 0, "matrix_fp": "/home/ayana/hisparse-xls/data/spmv1.json", "latency": 1, "num_streams": 2, "addr_sig": "t__streaming_addr", "pld_sig": "t__streaming_payload_one"}

    dut.t__multistream_payload_type_two__0_rdy.value = 1
    dut.t__multistream_payload_type_two__1_rdy.value = 1
    await tester.start(
        hisparse.matrix_loader_regular_driver,
        hisparse.matrix_loader_split_driver,
        reset=True, 
        coroutine_kwargs=[ml_metadata_kwargs, ml_streaming_kwargs]
    )
    for row_part in range(2):
        tester.input_driver.extend([{
            "t__cur_row_partition": row_part,
            "t__num_col_partitions": 2,
            "t__tot_num_partitions": 4
            }])
        await ClockCycles(dut.clk, 100)

@cocotb.test()
async def test_backpressure(dut):
    # deassert the downstream ready to ensure upstream index ready is deasserted as well, 
    # as well as test the proc doesnt request multiple indexes when the pipelined ram deasserts index ready
    # finally ensure already in flight requests are resolved
    tester = ProcTester(dut_entity=dut, clock=dut.clk, reset=dut.rst,
                    input_signals=[
                        "t__metadata_payload",
                        "t__streaming_payload_one",
                        "t__cur_row_partition",
                        "t__num_col_partitions",
                        "t__tot_num_partitions"
                    ], 
                    output_signals=[
                        "t__metadata_addr",
                        "t__streaming_addr",
                        "t__multistream_payload_type_two__0",
                        "t__multistream_payload_type_two__1"
                    ])
    ml_metadata_kwargs = {"hbm_chan": 0, "matrix_fp": "/home/ayana/hisparse-xls/data/spmv1.json", "latency": 2, "num_streams": 2, "addr_sig": "t__metadata_addr", "pld_sig": "t__metadata_payload"}
    ml_streaming_kwargs = {"hbm_chan": 0, "matrix_fp": "/home/ayana/hisparse-xls/data/spmv1.json", "latency": 2, "num_streams": 2, "addr_sig": "t__streaming_addr", "pld_sig": "t__streaming_payload_one"}
    dut.t__multistream_payload_type_two__0_rdy.value = 1
    dut.t__multistream_payload_type_two__1_rdy.value = 1
    await tester.start(
        hisparse.matrix_loader_regular_driver,
        hisparse.matrix_loader_split_driver,
        reset=True, 
        coroutine_kwargs=[ml_metadata_kwargs, ml_streaming_kwargs]
    )
    for row_part in range(2):
        tester.input_driver.extend([{
            "t__cur_row_partition": row_part,
            "t__num_col_partitions": 2,
            "t__tot_num_partitions": 4
            }])
        await ClockCycles(dut.clk, 15)
        dut.t__multistream_payload_type_two__0_rdy.value = 0
        await ClockCycles(dut.clk, 10)
        dut.t__multistream_payload_type_two__0_rdy.value = 1
        await ClockCycles(dut.clk, 20)

if __name__ == "__main__":
    runner(basepath=os.path.dirname(os.getcwd()),files=["__t__matrix_loader_send_0_next.sv", "__t__matrix_loader_recv_0_next.sv", "matrix_loader_opt_top.sv"], toplevel_module_name="matrix_loader_opt_top", test_module_name=os.path.basename(__file__)[:-3])