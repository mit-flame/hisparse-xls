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
                        "t__payload_type_one",
                        "t__cur_row_partition",
                        "t__num_col_partitions",
                        "t__tot_num_partitions"
                    ], 
                    output_signals=[
                        "t__payload_type_one_index",
                        "t__multistream_payload_type_two__0",
                        "t__multistream_payload_type_two__1"
                    ])
    mlkwargs = {"hbm_chan": 0, "matrix_fp": "/home/ayana/hisparse-xls/data/spmv1.json", "latency": 1, "num_streams": 2, "addr_sig": "t__payload_type_one_index", "pld_sig": "t__payload_type_one"}
    dut.t__multistream_payload_type_two__0_rdy.value = 1
    dut.t__multistream_payload_type_two__1_rdy.value = 1
    await tester.start(
        hisparse.matrix_loader_driver,
        reset=True, 
        coroutine_kwargs=[mlkwargs]
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
                        "t__payload_type_one",
                        "t__cur_row_partition",
                        "t__num_col_partitions",
                        "t__tot_num_partitions"
                    ], 
                    output_signals=[
                        "t__payload_type_one_index",
                        "t__multistream_payload_type_two__0",
                        "t__multistream_payload_type_two__1"
                    ])
    mlkwargs = {"hbm_chan": 0, "matrix_fp": "/home/ayana/hisparse-xls/data/spmv1.json", "latency": 1, "num_streams": 2, "addr_sig": "t__payload_type_one_index", "pld_sig": "t__payload_type_one"}
    dut.t__multistream_payload_type_two__0_rdy.value = 0
    dut.t__multistream_payload_type_two__1_rdy.value = 0
    await tester.start(
        hisparse.matrix_loader_driver,
        reset=True, 
        coroutine_kwargs=[mlkwargs]
    )
    for row_part in range(2):
        tester.input_driver.extend([{
            "t__cur_row_partition": row_part,
            "t__num_col_partitions": 2,
            "t__tot_num_partitions": 4
            }])
        await ClockCycles(dut.clk, 30)
        dut.t__multistream_payload_type_two__0_rdy.value = 1
        await ClockCycles(dut.clk, 10)
        dut.t__multistream_payload_type_two__1_rdy.value = 1
        await ClockCycles(dut.clk, 30)



if __name__ == "__main__":
    runner(basepath=os.path.dirname(os.getcwd()),files=["__t__matrix_loader_0_next.sv"], toplevel_module_name="__t__matrix_loader_0_next", test_module_name=os.path.basename(__file__)[:-3])