##########################################
# edit paths here
IR_PATH := ~/xls/bazel-bin/xls/dslx/ir_convert/ir_converter_main
OPT_PATH := ~/xls/bazel-bin/xls/tools/opt_main
CODEGEN_PATH := ~/xls/bazel-bin/xls/tools/codegen_main
INTERPRETER_PATH := ~/xls/bazel-bin/xls/dslx/interpreter_main

# codegen modifiable constants

# presets for spmv 1 and 2
NUM_STREAMS := 2
NUM_CLUSTERS := 1
NUM_KERNELS := 1
ARBITER_STAGES := 5
VB_SIZE := 4
OB_SIZE := 4
QUEUE_DEPTH := 2

# presets for spmv 3
# NUM_STREAMS := 2
# NUM_CLUSTERS := 1
# NUM_KERNELS := 1
# ARBITER_STAGES := 5
# VB_SIZE := 8
# OB_SIZE := 8
# QUEUE_DEPTH := 2

# inferred constants
OB_DIVIDED_BY_NUM_STREAMS := $(shell expr $(OB_SIZE) / $(NUM_STREAMS))
VB_BANK_SIZE := $(shell expr $(VB_SIZE) / $(NUM_STREAMS))
VECTOR_PAYLOAD_ONE_BITWIDTH := $(shell expr \( $(NUM_STREAMS) + 1 \) \* 32)
FLUSH_ITERS := $(shell expr $(NUM_STREAMS) \* $(ARBITER_STAGES))

# constants
IDEAL_SIM_DSLX_PATH := --dslx_path="xls/ideal/matrix_loader:xls/ideal/pe:xls/ideal/result_draining:xls/ideal/shuffle:xls/ideal/vector_loader"
ACTUAL_SIM_DSLX_PATH := --dslx_path="xls/actual/matrix_loader:xls/actual/pe:xls/actual/result_draining:xls/actual/shuffle:xls/actual/vector_loader"
ACTUAL_CODEGEN_DSLX_PATH := --dslx_path="../xls/actual/matrix_loader:../xls/actual/pe:../xls/actual/result_draining:../xls/actual/shuffle:../xls/actual/vector_loader"
OPT_CODEGEN_DSLX_PATH := --dslx_path="../xls/opt/matrix_loader:../xls/opt/pe:../xls/opt/result_draining:../xls/opt/shuffle:../xls/opt/vector_loader"
MODE ?= # supports actual or opt
##########################################

list:
	@printf "targets:\n\tcodegen: all MODE=[actual or opt]\n\tsimulation: ideal, actual, opt\n"

# simulation targets
ideal:
	$(INTERPRETER_PATH) xls/ideal/single_cluster_test.x $(IDEAL_SIM_DSLX_PATH) --alsologtostderr

actual:
	$(INTERPRETER_PATH) xls/actual/single_cluster_test.x $(ACTUAL_SIM_DSLX_PATH) --alsologtostderr

opt:
	$(INTERPRETER_PATH) xls/opt/single_cluster_test.x --dslx_path="xls/opt/matrix_loader:xls/opt/pe:xls/opt/result_draining:xls/opt/shuffle:xls/opt/vector_loader" --alsologtostderr

# codegen targets
clean:
	cd hdl; mv single_cluster_opt.sv /tmp/
	cd hdl; mv single_cluster_actual.sv /tmp/
	cd hdl; mv matrix_loader_opt_top.sv /tmp/
	cd hdl; rm *
	cd hdl; mv /tmp/single_cluster_opt.sv .
	cd hdl; mv /tmp/single_cluster_actual.sv .
	cd hdl; mv /tmp/matrix_loader_opt_top.sv .

ifeq ($(MODE),actual)
all: sf sf_core arb ml vl vau vunpack pe cpacker cmerger kmerger
else ifeq ($(MODE),opt)
all: sod_syncer eos_syncer sf_core arb ml_recv ml_send ml_addr_arb ml_pld_arb vl vau_send vau_recv vau_addr_arb vunpack pe_send pe_recv pe_addr_arb cpacker cmerger kmerger
endif
# intermediate targets
MODE_REQUIRED_TARGETS := all sf sf_core arb ml vl vau vunpack pe cpacker cmerger kmerger
ifneq ($(filter $(MODE_REQUIRED_TARGETS),$(MAKECMDGOALS)),)

ifeq ($(filter $(MODE),actual opt),)
$(error Use MODE=actual or MODE=opt)
endif

endif

ifeq ($(MODE),actual)
CODEGEN_DSLX_PATH := $(ACTUAL_CODEGEN_DSLX_PATH)
II := 3
OPT_LEVEL := 
SF_CODEGEN_FLAGS := --pipeline_stages=3 --worst_case_throughput=$(II) --delay_model=unit --reset=rst
SF_CORE_CODEGEN_FLAGS := --pipeline_stages=3 --worst_case_throughput=$(II) --delay_model=unit --reset=rst
ARBITER_CODEGEN_FLAGS := --pipeline_stages=$(ARBITER_STAGES) --worst_case_throughput=$(II) --flop_inputs_kind=skid --delay_model=unit --reset=rst
ML_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --io_constraints=t__payload_type_one_index:send:t__payload_type_one:recv:2:2 --worst_case_throughput=$(II)
VL_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --io_constraints=t__hbm_vector_addr:send:t__hbm_vector_payload:recv:2:2 --worst_case_throughput=$(II)
VECBUF_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --io_constraints=t__vecbuf_bank_addr:send:t__vecbuf_dout:send:2:2,t__vecbuf_bank_addr:send:t__vecbuf_din:recv:2:2 --worst_case_throughput=$(II)
VUNPACK_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
PE_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --io_constraints=t__vecbuf_bank_addr:send:t__vecbuf_bank_dout:send:2:2,t__vecbuf_bank_addr:send:t__vecbuf_bank_din:recv:2:2 --worst_case_throughput=$(II)
CPACKER_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
CMERGER_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
KMERGER_CODEGEN_FLAGS := --io_constraints=t__hbm_vector_addr:send:t__hbm_vector_payload:send:2:2 --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
endif
ifeq ($(MODE),opt)
# memories are one cycle read, one cycle write
CODEGEN_DSLX_PATH := $(OPT_CODEGEN_DSLX_PATH)
II := 1
OPT_LEVEL := --opt_level=3
GENERIC_SYNCER_CODEGEN_FLAGS := --pipeline_stages=3 --worst_case_throughput=$(II) --delay_model=unit --reset=rst
SF_CORE_CODEGEN_FLAGS := --pipeline_stages=3 --worst_case_throughput=$(II) --delay_model=unit --reset=rst --flop_inputs_kind=skid
ARBITER_CODEGEN_FLAGS := --pipeline_stages=$(ARBITER_STAGES) --worst_case_throughput=$(II) --flop_inputs_kind=skid --delay_model=unit --reset=rst
ML_RECV_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
ML_SEND_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
ML_ADDR_ARBITER_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
ML_PLD_ARBITER_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
VL_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
VAU_SEND_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
VAU_RECV_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
VUNPACK_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
PE_SEND_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
PE_RECV_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
PE_ADDR_ARBITER_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
CPACKER_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
CMERGER_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
KMERGER_CODEGEN_FLAGS := --pipeline_stages=3 --delay_model=unit --reset=rst --worst_case_throughput=$(II)
endif

.PHONY: sf
sf: hdl/__t__shuffler_0_next.sv
hdl/__t__shuffler_0_next.sv: xls/$(MODE)/shuffle/shuffler.x
	cat xls/$(MODE)/shuffle/shuffler.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=shuffler > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(SF_CODEGEN_FLAGS) t.opt.ir > __t__shuffler_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: sod_syncer
sod_syncer: hdl/__t__sod_syncer_0_next.sv
hdl/__t__sod_syncer_0_next.sv: xls/$(MODE)/shuffle/generic_syncer.x
	cat xls/$(MODE)/shuffle/generic_syncer.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32, COMMAND: u2>//g' hdl/t.x
	sed -i -e 's/generic_syncer/sod_syncer/g' hdl/t.x	
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	sed -i -e 's/COMMAND/u2: 1/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=sod_syncer > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(GENERIC_SYNCER_CODEGEN_FLAGS) t.opt.ir > __t__sod_syncer_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: eos_syncer
eos_syncer: hdl/__t__eos_syncer_0_next.sv
hdl/__t__eos_syncer_0_next.sv: xls/$(MODE)/shuffle/generic_syncer.x
	cat xls/$(MODE)/shuffle/generic_syncer.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32, COMMAND: u2>//g' hdl/t.x
	sed -i -e 's/generic_syncer/eos_syncer/g' hdl/t.x	
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	sed -i -e 's/COMMAND/u2: 3/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=eos_syncer > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(GENERIC_SYNCER_CODEGEN_FLAGS) t.opt.ir > __t__eos_syncer_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: sf_core
sf_core: hdl/__t__shuffler_core_0_next.sv
hdl/__t__shuffler_core_0_next.sv: xls/$(MODE)/shuffle/shuffler_core.x
	cat xls/$(MODE)/shuffle/shuffler_core.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32, FLUSH_ITERS: u32>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	sed -i -e 's/FLUSH_ITERS/u32: $(FLUSH_ITERS)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=shuffler_core > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(SF_CORE_CODEGEN_FLAGS) t.opt.ir > __t__shuffler_core_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: arb
arb: hdl/__t__arbiter_wrapper_0_next.sv
hdl/__t__arbiter_wrapper_0_next.sv: xls/$(MODE)/shuffle/arbiter.x
	cat xls/$(MODE)/shuffle/arbiter.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32>//g' hdl/t.x
	sed -i -e 's/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=arbiter_wrapper > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(ARBITER_CODEGEN_FLAGS) t.opt.ir > __t__arbiter_wrapper_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: ml_recv
ml_recv: hdl/__t__matrix_loader_recv_0_next.sv
hdl/__t__matrix_loader_recv_0_next.sv: xls/$(MODE)/matrix_loader/matrix_loader_recv.x
	cat xls/$(MODE)/matrix_loader/matrix_loader_recv.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=matrix_loader_recv > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(ML_RECV_CODEGEN_FLAGS) t.opt.ir > __t__matrix_loader_recv_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: ml_send
ml_send: hdl/__t__matrix_loader_send_0_next.sv
hdl/__t__matrix_loader_send_0_next.sv: xls/$(MODE)/matrix_loader/matrix_loader_send.x
	cat xls/$(MODE)/matrix_loader/matrix_loader_send.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=matrix_loader_send > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(ML_SEND_CODEGEN_FLAGS) t.opt.ir > __t__matrix_loader_send_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: ml_addr_arb
ml_addr_arb: hdl/__t__matrix_loader_addr_arbiter_0_next.sv
hdl/__t__matrix_loader_addr_arbiter_0_next.sv: xls/$(MODE)/matrix_loader/matrix_loader_addr_arbiter.x
	cat xls/$(MODE)/matrix_loader/matrix_loader_addr_arbiter.x > hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=matrix_loader_addr_arbiter > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(ML_ADDR_ARBITER_CODEGEN_FLAGS) t.opt.ir > __t__matrix_loader_addr_arbiter_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: ml_pld_arb
ml_pld_arb: hdl/__t__matrix_loader_pld_arbiter_0_next.sv
hdl/__t__matrix_loader_pld_arbiter_0_next.sv: xls/$(MODE)/matrix_loader/matrix_loader_pld_arbiter.x
	cat xls/$(MODE)/matrix_loader/matrix_loader_pld_arbiter.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=matrix_loader_pld_arbiter > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(ML_PLD_ARBITER_CODEGEN_FLAGS) t.opt.ir > __t__matrix_loader_pld_arbiter_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: ml
ml: hdl/__t__matrix_loader_0_next.sv
hdl/__t__matrix_loader_0_next.sv: xls/$(MODE)/matrix_loader/matrix_loader.x
	cat xls/$(MODE)/matrix_loader/matrix_loader.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=matrix_loader > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(ML_CODEGEN_FLAGS) t.opt.ir > __t__matrix_loader_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: vl
vl: hdl/__t__vector_loader_0_next.sv
hdl/__t__vector_loader_0_next.sv: xls/$(MODE)/vector_loader/vector_loader.x
	cat xls/$(MODE)/vector_loader/vector_loader.x > hdl/t.x
	sed -i -e 's/<NUM_KERNELS: u32,NUM_STREAMS: u32,VB_SIZE: u32,PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	sed -i -e '/NUM_KERNELS:/!s/NUM_KERNELS/u32: $(NUM_KERNELS)/g' hdl/t.x
	sed -i -e '/VB_SIZE:/!s/VB_SIZE/u32: $(VB_SIZE)/g' hdl/t.x
	sed -i -e '/PAYLOAD_ONE_BITWIDTH:/!s/PAYLOAD_ONE_BITWIDTH/u32: $(VECTOR_PAYLOAD_ONE_BITWIDTH)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=vector_loader > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(VL_CODEGEN_FLAGS) t.opt.ir > __t__vector_loader_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: vau
vau: hdl/__t__vecbuf_access_unit_0_next.sv
hdl/__t__vecbuf_access_unit_0_next.sv: xls/$(MODE)/vector_loader/vector_buffer_access_unit.x
	cat xls/$(MODE)/vector_loader/vector_buffer_access_unit.x > hdl/t.x
	sed -i -e 's/<BANK_SIZE: u32,NUM_STREAMS: u32>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	sed -i -e '/BANK_SIZE:/!s/BANK_SIZE/u32: $(VB_BANK_SIZE)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=vecbuf_access_unit > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(VECBUF_CODEGEN_FLAGS) t.opt.ir > __t__vecbuf_access_unit_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: vau_send
vau_send: hdl/__t__vba_send_0_next.sv
hdl/__t__vba_send_0_next.sv: xls/$(MODE)/vector_loader/vba_send.x
	cat xls/$(MODE)/vector_loader/vba_send.x > hdl/t.x
	sed -i -e 's/<BANK_SIZE: u32,NUM_STREAMS: u32>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	sed -i -e '/BANK_SIZE:/!s/BANK_SIZE/u32: $(VB_BANK_SIZE)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=vba_send > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(VAU_SEND_CODEGEN_FLAGS) t.opt.ir > __t__vba_send_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: vau_recv
vau_recv: hdl/__t__vba_recv_0_next.sv
hdl/__t__vba_recv_0_next.sv: xls/$(MODE)/vector_loader/vba_recv.x
	cat xls/$(MODE)/vector_loader/vba_recv.x > hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=vba_recv > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(VAU_RECV_CODEGEN_FLAGS) t.opt.ir > __t__vba_recv_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: vau_addr_arb
vau_addr_arb: hdl/__t__vba_addr_arbiter_0_next.sv
hdl/__t__vba_addr_arbiter_0_next.sv: xls/$(MODE)/vector_loader/vba_addr_arbiter.x
	cat xls/$(MODE)/vector_loader/vba_addr_arbiter.x > hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=vba_addr_arbiter > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(VAU_RECV_CODEGEN_FLAGS) t.opt.ir > __t__vba_addr_arbiter_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: vunpack
vunpack: hdl/__t__vector_unpacker_0_next.sv
hdl/__t__vector_unpacker_0_next.sv: xls/$(MODE)/vector_loader/vector_unpacker.x
	cat xls/$(MODE)/vector_loader/vector_unpacker.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32, PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	sed -i -e '/PAYLOAD_ONE_BITWIDTH:/!s/PAYLOAD_ONE_BITWIDTH/u32: $(VECTOR_PAYLOAD_ONE_BITWIDTH)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=vector_unpacker > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(VUNPACK_CODEGEN_FLAGS) t.opt.ir > __t__vector_unpacker_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: pe
pe: hdl/__t__processing_engine_0_next.sv
hdl/__t__processing_engine_0_next.sv: xls/$(MODE)/pe/pe.x
	cat xls/$(MODE)/pe/pe.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32, QUEUE_DEPTH: u32>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	sed -i -e '/QUEUE_DEPTH:/!s/QUEUE_DEPTH/u32: $(QUEUE_DEPTH)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=processing_engine > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(PE_CODEGEN_FLAGS) t.opt.ir > __t__processing_engine_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: pe_send
pe_send: hdl/__t__pe_send_0_next.sv
hdl/__t__pe_send_0_next.sv: xls/$(MODE)/pe/pe_send.x
	cat xls/$(MODE)/pe/pe_send.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=pe_send > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(PE_SEND_CODEGEN_FLAGS) t.opt.ir > __t__pe_send_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: pe_recv
pe_recv: hdl/__t__pe_recv_0_next.sv
hdl/__t__pe_recv_0_next.sv: xls/$(MODE)/pe/pe_recv.x
	cat xls/$(MODE)/pe/pe_recv.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32, QUEUE_DEPTH: u32>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	sed -i -e '/QUEUE_DEPTH:/!s/QUEUE_DEPTH/u32: $(QUEUE_DEPTH)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=pe_recv > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(PE_RECV_CODEGEN_FLAGS) t.opt.ir > __t__pe_recv_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: pe_addr_arb
pe_addr_arb: hdl/__t__pe_addr_arbiter_0_next.sv
hdl/__t__pe_addr_arbiter_0_next.sv: xls/$(MODE)/pe/pe_addr_arbiter.x
	cat xls/$(MODE)/pe/pe_addr_arbiter.x > hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=pe_addr_arbiter > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(PE_ADDR_ARBITER_CODEGEN_FLAGS) t.opt.ir > __t__pe_addr_arbiter_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: cpacker
cpacker: hdl/__t__cluster_packer_0_next.sv
hdl/__t__cluster_packer_0_next.sv: xls/$(MODE)/result_draining/cluster_packer.x
	cat xls/$(MODE)/result_draining/cluster_packer.x > hdl/t.x
	sed -i -e 's/<NUM_STREAMS: u32,PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}>//g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	sed -i -e '/PAYLOAD_ONE_BITWIDTH:/!s/PAYLOAD_ONE_BITWIDTH/u32: $(VECTOR_PAYLOAD_ONE_BITWIDTH)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=cluster_packer > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(CPACKER_CODEGEN_FLAGS) t.opt.ir > __t__cluster_packer_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: cmerger
cmerger: hdl/__t__clusters_results_merger_0_next.sv
hdl/__t__clusters_results_merger_0_next.sv: xls/$(MODE)/result_draining/clusters_results_merger.x
	cat xls/$(MODE)/result_draining/clusters_results_merger.x > hdl/t.x
	sed -i -e 's/<NUM_CLUSTERS: u32, NUM_STREAMS: u32, PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}>//g' hdl/t.x
	sed -i -e '/NUM_CLUSTERS:/!s/NUM_CLUSTERS/u32: $(NUM_CLUSTERS)/g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	sed -i -e '/PAYLOAD_ONE_BITWIDTH:/!s/PAYLOAD_ONE_BITWIDTH/u32: $(VECTOR_PAYLOAD_ONE_BITWIDTH)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=clusters_results_merger > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(CMERGER_CODEGEN_FLAGS) t.opt.ir > __t__clusters_results_merger_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir

.PHONY: kmerger
kmerger: hdl/__t__kernels_results_merger_0_next.sv
hdl/__t__kernels_results_merger_0_next.sv: xls/$(MODE)/result_draining/kernels_results_merger.x
	cat xls/$(MODE)/result_draining/kernels_results_merger.x > hdl/t.x
	sed -i -e 's/<NUM_KERNELS: u32, OB_DIVIDED_BY_PACK_SIZE: u32, NUM_STREAMS: u32, PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}>//g' hdl/t.x
	sed -i -e '/NUM_KERNELS:/!s/NUM_KERNELS/u32: $(NUM_KERNELS)/g' hdl/t.x
	sed -i -e '/NUM_STREAMS:/!s/NUM_STREAMS/u32: $(NUM_STREAMS)/g' hdl/t.x
	sed -i -e '/OB_DIVIDED_BY_PACK_SIZE:/!s/OB_DIVIDED_BY_PACK_SIZE/u32: $(OB_DIVIDED_BY_NUM_STREAMS)/g' hdl/t.x
	sed -i -e '/PAYLOAD_ONE_BITWIDTH:/!s/PAYLOAD_ONE_BITWIDTH/u32: $(VECTOR_PAYLOAD_ONE_BITWIDTH)/g' hdl/t.x
	cd hdl; $(IR_PATH) $(CODEGEN_DSLX_PATH) t.x --top=kernels_results_merger > t.ir
	cd hdl; $(OPT_PATH) $(OPT_LEVEL) t.ir > t.opt.ir
	cd hdl; $(CODEGEN_PATH) $(KMERGER_CODEGEN_FLAGS) t.opt.ir > __t__kernels_results_merger_0_next.sv
	rm hdl/t.x
	rm hdl/t.ir
	rm hdl/t.opt.ir
