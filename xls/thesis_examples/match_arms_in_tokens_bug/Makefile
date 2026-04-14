# edit paths here
IR_PATH := ~/xls/bazel-bin/xls/dslx/ir_convert/ir_converter_main
OPT_PATH := ~/xls/bazel-bin/xls/tools/opt_main
CODEGEN_PATH := ~/xls/bazel-bin/xls/tools/codegen_main
INTERPRETER_PATH := ~/xls/bazel-bin/xls/dslx/interpreter_main

# IR_PATH := ~/xls_new/xls/bazel-bin/xls/dslx/ir_convert/ir_converter_main
# OPT_PATH := ~/xls_new/xls/bazel-bin/xls/tools/opt_main
# CODEGEN_PATH := ~/xls_new/xls/bazel-bin/xls/tools/codegen_main
# INTERPRETER_PATH := ~/xls_new/xls/bazel-bin/xls/dslx/interpreter_main


bug:
	$(IR_PATH) example.x --top=example > e.ir
	$(OPT_PATH) e.ir > e.opt.ir
	$(CODEGEN_PATH) --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=3 e.opt.ir > e.sv

clean:
	rm e.ir
	rm e.opt.ir
	rm e.sv