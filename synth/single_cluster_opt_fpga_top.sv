// note din is what we are writing out, i suppose i messed that up but im consistent
module single_cluster_opt_fpga_top(
    input wire clk,
    input wire reset,
    output wire finished,
    output wire [31:0] num_cycles,
    output wire [7:0] [31:0] final_vec,

    // ML BRAM stuff
    output wire [31:0] ml_bram_addr,
    input wire [127:0] ml_bram_dout,
    output wire [31:0] ml_bram_din, // <-- unused
    output wire ml_bram_wea,
    output wire ml_bram_enable,

    // VL BRAM stuff
    output wire [31:0] vl_bram_addr,
    input wire [63:0] vl_bram_dout,
    output wire [31:0] vl_bram_din, // <-- unused
    output wire vl_bram_wea,
    output wire vl_bram_enable,

    // VAU0 BRAM stuff
    output wire [31:0] vau0_bram_addr,
    input wire [31:0] vau0_bram_dout,
    output wire [31:0] vau0_bram_din,
    output wire vau0_bram_wea,
    output wire vau0_bram_enable,

    // VAU1 BRAM stuff
    output wire [31:0] vau1_bram_addr,
    input wire [31:0] vau1_bram_dout,
    output wire [31:0] vau1_bram_din,
    output wire vau1_bram_wea,
    output wire vau1_bram_enable,

    // ----------THESE SHOULD BE TWO PORTS ON THE SAME BRAM------------
    // PE0-Send BRAM stuff
    output wire [31:0] pe0s_bram_addr,
    input wire [31:0] pe0s_bram_dout,
    output wire [31:0] pe0s_bram_din,
    output wire pe0s_bram_wea,
    output wire pe0s_bram_enable,
    // PE0-Recv BRAM stuff
    output wire [31:0] pe0a_bram_addr,
    input wire [31:0] pe0a_bram_dout, // <-- unused
    output wire [31:0] pe0a_bram_din,
    output wire pe0a_bram_wea,
    output wire pe0a_bram_enable,
    // ----------------------------------------------------------------

    // ----------THESE SHOULD BE TWO PORTS ON THE SAME BRAM------------
    // PE1-Send BRAM stuff
    output wire [31:0] pe1s_bram_addr,
    input wire [31:0] pe1s_bram_dout,
    output wire [31:0] pe1s_bram_din,
    output wire pe1s_bram_wea,
    output wire pe1s_bram_enable,
    // PE1-Recv BRAM stuff
    output wire [31:0] pe1a_bram_addr,
    input wire [31:0] pe1a_bram_dout, // <-- unused
    output wire [31:0] pe1a_bram_din,
    output wire pe1a_bram_wea,
    output wire pe1a_bram_enable
    // ----------------------------------------------------------------
);
    // ML-send driver outputs
    logic [31:0] driver_t__cur_row_partition;
    logic driver_t__cur_row_partition_vld;
    logic [31:0] driver_t__num_col_partitions;
    logic driver_t__num_col_partitions_vld;
    logic [31:0] driver_t__tot_num_partitions;
    logic driver_t__tot_num_partitions_vld;
    // VL driver outputs
    logic [31:0] driver_t__num_matrix_cols;
    logic driver_t__num_matrix_cols_vld;
    // VAU 0 driver outputs
    logic [31:0] driver_vecbuf0_t__num_col_partitions;
    logic driver_vecbuf0_t__num_col_partitions_vld;
    // VAU 1 driver outputs
    logic [31:0] driver_vecbuf1_t__num_col_partitions;
    logic driver_vecbuf1_t__num_col_partitions_vld;
    // PE0_send driver outputs
    logic [29:0] driver_pe0_t__num_rows_updated;
    logic driver_pe0_t__num_rows_updated_vld;
    logic [31:0] driver_pe0_t__stream_id;
    logic driver_pe0_t__stream_id_vld;
    // PE1_send driver outputs
    logic [29:0] driver_pe1_t__num_rows_updated;
    logic driver_pe1_t__num_rows_updated_vld;
    logic [31:0] driver_pe1_t__stream_id;
    logic driver_pe1_t__stream_id_vld;
    // kmerger driver outputs
    logic [31:0] driver_kmerger_t__current_row_partition;
    logic driver_kmerger_t__current_row_partition_vld;
    logic driver_kmerger_t__hbm_vector_addr_rdy;
    logic driver_kmerger_t__hbm_vector_payload_rdy;
    logic [31:0] driver_kmerger_t__num_hbm_channels_each_kernel;
    logic driver_kmerger_t__num_hbm_channels_each_kernel_vld;

    single_cluster_opt_driver driver(
        .clk(clk),
        .reset(reset),
        .finished(finished),
        .num_cycles(num_cycles),
        .final_vec(final_vec),
        // ML-send inputs/outputs
        .t__cur_row_partition(driver_t__cur_row_partition),
        .t__cur_row_partition_vld(driver_t__cur_row_partition_vld),
        .t__num_col_partitions(driver_t__num_col_partitions),
        .t__num_col_partitions_vld(driver_t__num_col_partitions_vld),
        .t__tot_num_partitions(driver_t__tot_num_partitions),
        .t__tot_num_partitions_vld(driver_t__tot_num_partitions_vld),
        .t__cur_row_partition_rdy(dut_t__cur_row_partition_rdy),
        .t__num_col_partitions_rdy(dut_t__num_col_partitions_rdy),
        .t__tot_num_partitions_rdy(dut_t__tot_num_partitions_rdy),
        // VL inputs/outputs
        .t__num_matrix_cols(driver_t__num_matrix_cols),
        .t__num_matrix_cols_vld(driver_t__num_matrix_cols_vld),
        .t__num_matrix_cols_rdy(dut_t__num_matrix_cols_rdy),
        // VAU 0 inputs/outputs
        .vecbuf0_t__num_col_partitions(driver_vecbuf0_t__num_col_partitions),
        .vecbuf0_t__num_col_partitions_vld(driver_vecbuf0_t__num_col_partitions_vld),
        .vecbuf0_t__num_col_partitions_rdy(dut_vecbuf0_t__num_col_partitions_rdy),
        // VAU 1 inputs/outputs
        .vecbuf1_t__num_col_partitions(driver_vecbuf1_t__num_col_partitions),
        .vecbuf1_t__num_col_partitions_vld(driver_vecbuf1_t__num_col_partitions_vld),
        .vecbuf1_t__num_col_partitions_rdy(dut_vecbuf1_t__num_col_partitions_rdy),
        // PE0_send inputs/outputs
        .pe0_t__num_rows_updated(driver_pe0_t__num_rows_updated),
        .pe0_t__num_rows_updated_vld(driver_pe0_t__num_rows_updated_vld),
        .pe0_t__num_rows_updated_rdy(dut_pe0_t__num_rows_updated_rdy),
        // PE0_recv inputs/oututs
        .pe0_t__stream_id(driver_pe0_t__stream_id),
        .pe0_t__stream_id_vld(driver_pe0_t__stream_id_vld),
        .pe0_t__stream_id_rdy(dut_pe0_t__stream_id_rdy),
        // PE1_send inputs/outputs
        .pe1_t__num_rows_updated(driver_pe1_t__num_rows_updated),
        .pe1_t__num_rows_updated_vld(driver_pe1_t__num_rows_updated_vld),
        .pe1_t__num_rows_updated_rdy(dut_pe1_t__num_rows_updated_rdy),
        // PE1_recv inputs/oututs
        .pe1_t__stream_id(driver_pe1_t__stream_id),
        .pe1_t__stream_id_vld(driver_pe1_t__stream_id_vld),
        .pe1_t__stream_id_rdy(dut_pe1_t__stream_id_rdy),
        // kmerger inputs/outputs
        .kmerger_t__current_row_partition(driver_kmerger_t__current_row_partition),
        .kmerger_t__current_row_partition_vld(driver_kmerger_t__current_row_partition_vld),
        .kmerger_t__hbm_vector_addr_rdy(driver_kmerger_t__hbm_vector_addr_rdy),
        .kmerger_t__hbm_vector_payload_rdy(driver_kmerger_t__hbm_vector_payload_rdy),
        .kmerger_t__num_hbm_channels_each_kernel(driver_kmerger_t__num_hbm_channels_each_kernel),
        .kmerger_t__num_hbm_channels_each_kernel_vld(driver_kmerger_t__num_hbm_channels_each_kernel_vld),
        .kmerger_t__current_row_partition_rdy(dut_kmerger_t__current_row_partition_rdy),
        .kmerger_t__hbm_vector_addr(dut_kmerger_t__hbm_vector_addr),
        .kmerger_t__hbm_vector_addr_vld(dut_kmerger_t__hbm_vector_addr_vld),
        .kmerger_t__hbm_vector_payload(dut_kmerger_t__hbm_vector_payload),
        .kmerger_t__hbm_vector_payload_vld(dut_kmerger_t__hbm_vector_payload_vld),
        .kmerger_t__num_hbm_channels_each_kernel_rdy(dut_kmerger_t__num_hbm_channels_each_kernel_rdy)
    );

  // ML-send dut outputs
  logic [63:0] dut_t__unified_addr;
  logic dut_t__unified_addr_vld;
  logic dut_t__cur_row_partition_rdy;
  logic dut_t__num_col_partitions_rdy;
  logic dut_t__tot_num_partitions_rdy;
  // ML-recv dut outputs
  logic dut_t__unified_pld_rdy;
  // VL dut outputs
  logic [31:0] dut_t__hbm_vector_addr;
  logic dut_t__hbm_vector_addr_vld;
  logic dut_t__hbm_vector_payload_rdy;
  logic dut_t__num_matrix_cols_rdy;
  // VAU 0 dut outputs
  logic dut_vecbuf0_t__num_col_partitions_rdy;
  logic [127:0] dut_vecbuf0_t__unified_addr;
  logic dut_vecbuf0_t__unified_addr_vld;
  logic dut_vecbuf0_t__streaming_pld_rdy;
  // VAU 1 dut outputs
  logic dut_vecbuf1_t__num_col_partitions_rdy;
  logic [127:0] dut_vecbuf1_t__unified_addr;
  logic dut_vecbuf1_t__unified_addr_vld;
  logic dut_vecbuf1_t__streaming_pld_rdy;
  // PE0_send dut outputs
  logic dut_pe0_t__num_rows_updated_rdy;
  // PE0_arbiter dut outputs
  logic [127:0] dut_pe0_t__unified_addr;
  logic dut_pe0_t__unified_addr_vld;
  // PE0_recv dut oututs
  logic dut_pe0_t__stream_id_rdy;
  logic dut_pe0_t__unified_pld_rdy;
  logic [127:0] dut_pe0_t__accumulation_addr;
  logic dut_pe0_t__accumulation_addr_vld;
  // PE1_send dut outputs
  logic dut_pe1_t__num_rows_updated_rdy;
  // PE1_arbiter dut outputs
  logic [127:0] dut_pe1_t__unified_addr;
  logic dut_pe1_t__unified_addr_vld;
  // PE1_recv dut oututs
  logic dut_pe1_t__stream_id_rdy;
  logic dut_pe1_t__unified_pld_rdy;
  logic [127:0] dut_pe1_t__accumulation_addr;
  logic dut_pe1_t__accumulation_addr_vld;
  // kmerger dut outputs
  logic dut_kmerger_t__current_row_partition_rdy;
  logic [31:0] dut_kmerger_t__hbm_vector_addr;
  logic dut_kmerger_t__hbm_vector_addr_vld;
  logic [63:0] dut_kmerger_t__hbm_vector_payload;
  logic dut_kmerger_t__hbm_vector_payload_vld;
  logic dut_kmerger_t__num_hbm_channels_each_kernel_rdy;

    single_cluster_opt dut(
        .clk(clk),
        .rst(reset),
        // ML-send inputs/outputs
        .t__cur_row_partition(driver_t__cur_row_partition),
        .t__cur_row_partition_vld(driver_t__cur_row_partition_vld),
        .t__num_col_partitions(driver_t__num_col_partitions),
        .t__num_col_partitions_vld(driver_t__num_col_partitions_vld),
        .t__tot_num_partitions(driver_t__tot_num_partitions),
        .t__tot_num_partitions_vld(driver_t__tot_num_partitions_vld),
        .t__unified_addr_rdy(ml_bram_wrapper_upstream_ready),
        .t__unified_addr(dut_t__unified_addr),
        .t__unified_addr_vld(dut_t__unified_addr_vld),
        .t__cur_row_partition_rdy(dut_t__cur_row_partition_rdy),
        .t__num_col_partitions_rdy(dut_t__num_col_partitions_rdy),
        .t__tot_num_partitions_rdy(dut_t__tot_num_partitions_rdy),
        // ML-recv inputs/outputs
        .t__unified_pld(ml_bram_wrapper_unified_pld),
        .t__unified_pld_vld(ml_bram_wrapper_p_vld),
        .t__unified_pld_rdy(dut_t__unified_pld_rdy),
        // VL inputs/outputs
        .t__hbm_vector_addr_rdy(vl_bram_wrapper_upstream_ready),
        .t__hbm_vector_payload(vl_bram_wrapper_unified_pld),
        .t__hbm_vector_payload_vld(vl_bram_wrapper_p_vld),
        .t__num_matrix_cols(driver_t__num_matrix_cols),
        .t__num_matrix_cols_vld(driver_t__num_matrix_cols_vld),
        .t__hbm_vector_addr(dut_t__hbm_vector_addr),
        .t__hbm_vector_addr_vld(dut_t__hbm_vector_addr_vld),
        .t__hbm_vector_payload_rdy(dut_t__hbm_vector_payload_rdy),
        .t__num_matrix_cols_rdy(dut_t__num_matrix_cols_rdy),
        // VAU 0 inputs/outputs
        .vecbuf0_t__num_col_partitions(driver_vecbuf0_t__num_col_partitions),
        .vecbuf0_t__num_col_partitions_vld(driver_vecbuf0_t__num_col_partitions_vld),
        .vecbuf0_t__unified_addr_rdy(vau0_bram_wrapper_upstream_ready),
        .vecbuf0_t__streaming_pld(vau0_bram_wrapper_unified_pld),
        .vecbuf0_t__streaming_pld_vld(vau0_bram_wrapper_p_vld),
        .vecbuf0_t__num_col_partitions_rdy(dut_vecbuf0_t__num_col_partitions_rdy),
        .vecbuf0_t__unified_addr(dut_vecbuf0_t__unified_addr),
        .vecbuf0_t__unified_addr_vld(dut_vecbuf0_t__unified_addr_vld),
        .vecbuf0_t__streaming_pld_rdy(dut_vecbuf0_t__streaming_pld_rdy),
        // VAU 1 inputs/outputs
        .vecbuf1_t__num_col_partitions(driver_vecbuf1_t__num_col_partitions),
        .vecbuf1_t__num_col_partitions_vld(driver_vecbuf1_t__num_col_partitions_vld),
        .vecbuf1_t__unified_addr_rdy(vau1_bram_wrapper_upstream_ready),
        .vecbuf1_t__streaming_pld(vau1_bram_wrapper_unified_pld),
        .vecbuf1_t__streaming_pld_vld(vau1_bram_wrapper_p_vld),
        .vecbuf1_t__num_col_partitions_rdy(dut_vecbuf1_t__num_col_partitions_rdy),
        .vecbuf1_t__unified_addr(dut_vecbuf1_t__unified_addr),
        .vecbuf1_t__unified_addr_vld(dut_vecbuf1_t__unified_addr_vld),
        .vecbuf1_t__streaming_pld_rdy(dut_vecbuf1_t__streaming_pld_rdy),
        // PE0_send inputs/outputs
        .pe0_t__num_rows_updated(driver_pe0_t__num_rows_updated),
        .pe0_t__num_rows_updated_vld(driver_pe0_t__num_rows_updated_vld),
        .pe0_t__num_rows_updated_rdy(dut_pe0_t__num_rows_updated_rdy),
        // PE0_arbiter inputs/outputs
        .pe0_t__unified_addr_rdy(pe0s_bram_wrapper_upstream_ready),
        .pe0_t__unified_addr(dut_pe0_t__unified_addr),
        .pe0_t__unified_addr_vld(dut_pe0_t__unified_addr_vld),
        // PE0_recv inputs/oututs
        .pe0_t__stream_id(driver_pe0_t__stream_id),
        .pe0_t__stream_id_vld(driver_pe0_t__stream_id_vld),
        .pe0_t__unified_pld(pe0s_bram_wrapper_unified_pld),
        .pe0_t__unified_pld_vld(pe0s_bram_wrapper_p_vld),
        .pe0_t__accumulation_addr_rdy(1'b1),
        .pe0_t__dummy_accumulate_pld(pe0a_bram_wrapper_unified_pld),
        .pe0_t__dummy_accumulate_pld_vld(1'b0),
        .pe0_t__stream_id_rdy(dut_pe0_t__stream_id_rdy),
        .pe0_t__unified_pld_rdy(dut_pe0_t__unified_pld_rdy),
        .pe0_t__accumulation_addr(dut_pe0_t__accumulation_addr),
        .pe0_t__accumulation_addr_vld(dut_pe0_t__accumulation_addr_vld),
        // PE1_send inputs/outputs
        .pe1_t__num_rows_updated(driver_pe1_t__num_rows_updated),
        .pe1_t__num_rows_updated_vld(driver_pe1_t__num_rows_updated_vld),
        .pe1_t__num_rows_updated_rdy(dut_pe1_t__num_rows_updated_rdy),
        // PE1_arbiter inputs/outputs
        .pe1_t__unified_addr_rdy(pe1s_bram_wrapper_upstream_ready),
        .pe1_t__unified_addr(dut_pe1_t__unified_addr),
        .pe1_t__unified_addr_vld(dut_pe1_t__unified_addr_vld),
        // PE1_recv inputs/oututs
        .pe1_t__stream_id(driver_pe1_t__stream_id),
        .pe1_t__stream_id_vld(driver_pe1_t__stream_id_vld),
        .pe1_t__unified_pld(pe1s_bram_wrapper_unified_pld),
        .pe1_t__unified_pld_vld(pe1s_bram_wrapper_p_vld),
        .pe1_t__accumulation_addr_rdy(1'b1),
        .pe1_t__dummy_accumulate_pld(pe1a_bram_wrapper_unified_pld),
        .pe1_t__dummy_accumulate_pld_vld(1'b0),
        .pe1_t__stream_id_rdy(dut_pe1_t__stream_id_rdy),
        .pe1_t__unified_pld_rdy(dut_pe1_t__unified_pld_rdy),
        .pe1_t__accumulation_addr(dut_pe1_t__accumulation_addr),
        .pe1_t__accumulation_addr_vld(dut_pe1_t__accumulation_addr_vld),
        // kmerger inputs/outputs
        .kmerger_t__current_row_partition(driver_kmerger_t__current_row_partition),
        .kmerger_t__current_row_partition_vld(driver_kmerger_t__current_row_partition_vld),
        .kmerger_t__hbm_vector_addr_rdy(driver_kmerger_t__hbm_vector_addr_rdy),
        .kmerger_t__hbm_vector_payload_rdy(driver_kmerger_t__hbm_vector_payload_rdy),
        .kmerger_t__num_hbm_channels_each_kernel(driver_kmerger_t__num_hbm_channels_each_kernel),
        .kmerger_t__num_hbm_channels_each_kernel_vld(driver_kmerger_t__num_hbm_channels_each_kernel_vld),
        .kmerger_t__current_row_partition_rdy(dut_kmerger_t__current_row_partition_rdy),
        .kmerger_t__hbm_vector_addr(dut_kmerger_t__hbm_vector_addr),
        .kmerger_t__hbm_vector_addr_vld(dut_kmerger_t__hbm_vector_addr_vld),
        .kmerger_t__hbm_vector_payload(dut_kmerger_t__hbm_vector_payload),
        .kmerger_t__hbm_vector_payload_vld(dut_kmerger_t__hbm_vector_payload_vld),
        .kmerger_t__num_hbm_channels_each_kernel_rdy(dut_kmerger_t__num_hbm_channels_each_kernel_rdy)
    );

    // ml_bram_wrapper BRAM address extraction
    assign ml_bram_addr = dut_t__unified_addr[63:32];
    // ml_bram_wrapper enables
    assign ml_bram_wea = 0;
    assign ml_bram_enable = 1;
    // ml_bram_wrapper BRAM unified payload creation
    logic [159:0] ml_bram_wrapper_unified_pld;
    assign ml_bram_wrapper_unified_pld = {ml_bram_wrapper_p_dout, ml_bram_wrapper_p_info};
    // ml_bram_wrapper outputs
    logic ml_bram_wrapper_upstream_ready;
    logic [31:0] ml_bram_wrapper_p_info;
    logic ml_bram_wrapper_p_vld;
    logic [127:0] ml_bram_wrapper_p_dout;
    single_cluster_bram_info_pipeline #(.INFO_WIDTH(32), .READ_LATENCY(2), .DOUT_WIDTH(128)) ml_bram_wrapper (
        .clk(clk),
        .reset(reset),
        .info(dut_t__unified_addr[31:0]),
        .info_vld(dut_t__unified_addr_vld),
        .dout(ml_bram_dout),
        .downstream_ready(dut_t__unified_pld_rdy),
        //outputs
        .upstream_ready(ml_bram_wrapper_upstream_ready),
        .p_info(ml_bram_wrapper_p_info),
        .p_vld(ml_bram_wrapper_p_vld),
        .p_dout(ml_bram_wrapper_p_dout)
    ); 

    // ---despite VL not having info pipelined with it, it still needs the valid signal pipelined---
    // vl_bram_wrapper BRAM address extraction
    assign vl_bram_addr = dut_t__hbm_vector_addr;
    // vl_bram_wrapper enables
    assign vl_bram_wea = 0;
    assign vl_bram_enable = 1;
    // vl_bram_wrapper BRAM unified payload creation
    logic [63:0] vl_bram_wrapper_unified_pld;
    assign vl_bram_wrapper_unified_pld = vl_bram_wrapper_p_dout;
    // vl_bram_wrapper outputs
    logic vl_bram_wrapper_upstream_ready;
    logic [31:0] vl_bram_wrapper_p_info;
    logic vl_bram_wrapper_p_vld;
    logic [63:0] vl_bram_wrapper_p_dout;
    single_cluster_bram_info_pipeline #(.INFO_WIDTH(32), .READ_LATENCY(2), .DOUT_WIDTH(64)) vl_bram_wrapper (
        .clk(clk),
        .reset(reset),
        .info(0),
        .info_vld(dut_t__hbm_vector_addr_vld),
        .dout(vl_bram_dout),
        .downstream_ready(dut_t__hbm_vector_payload_rdy),
        //outputs
        .upstream_ready(vl_bram_wrapper_upstream_ready),
        .p_info(vl_bram_wrapper_p_info),
        .p_vld(vl_bram_wrapper_p_vld),
        .p_dout(vl_bram_wrapper_p_dout)
    ); 

    // vau0_bram_wrapper BRAM address extraction
    assign vau0_bram_addr = {3'b0, dut_vecbuf0_t__unified_addr[124:96]};
    // vau0_bram_wrapper enables
    assign vau0_bram_wea = dut_vecbuf0_t__unified_addr[127] && dut_vecbuf0_t__unified_addr_vld;
    assign vau0_bram_din = dut_vecbuf0_t__unified_addr[95:64];
    assign vau0_bram_enable = 1;
    // vau0_bram_wrapper BRAM unified payload creation
    logic [95:0] vau0_bram_wrapper_unified_pld;
    assign vau0_bram_wrapper_unified_pld = {vau0_bram_wrapper_p_info[63:32], vau0_bram_wrapper_p_dout, vau0_bram_wrapper_p_info[31:0]};
    // vau0_bram_wrapper outputs
    logic vau0_bram_wrapper_upstream_ready;
    logic [63:0] vau0_bram_wrapper_p_info;
    logic vau0_bram_wrapper_p_vld;
    logic [31:0] vau0_bram_wrapper_p_dout;
    single_cluster_bram_info_pipeline #(.INFO_WIDTH(64), .READ_LATENCY(2), .DOUT_WIDTH(32)) vau0_bram_wrapper (
        .clk(clk),
        .reset(reset),
        .info({dut_vecbuf0_t__unified_addr[126:125], dut_vecbuf0_t__unified_addr[29:0], dut_vecbuf0_t__unified_addr[63:32]}),
        // since write is enabled, we must ensure outgoing payloads are only valid if they originate from a read request
        .info_vld(dut_vecbuf0_t__unified_addr_vld && !dut_vecbuf0_t__unified_addr[127]),
        .downstream_ready(dut_vecbuf0_t__streaming_pld_rdy),
        .dout(vau0_bram_dout),
        //outputs
        .upstream_ready(vau0_bram_wrapper_upstream_ready),
        .p_info(vau0_bram_wrapper_p_info),
        .p_vld(vau0_bram_wrapper_p_vld),
        .p_dout(vau0_bram_wrapper_p_dout)
    ); 

    // vau1_bram_wrapper BRAM address extraction
    assign vau1_bram_addr = {3'b0, dut_vecbuf1_t__unified_addr[124:96]};
    // vau1_bram_wrapper enables
    assign vau1_bram_wea = dut_vecbuf1_t__unified_addr[127] && dut_vecbuf1_t__unified_addr_vld;
    assign vau1_bram_din = dut_vecbuf1_t__unified_addr[95:64];
    assign vau1_bram_enable = 1;
    // vau1_bram_wrapper BRAM unified payload creation
    logic [95:0] vau1_bram_wrapper_unified_pld;
    assign vau1_bram_wrapper_unified_pld = {vau1_bram_wrapper_p_info[63:32], vau1_bram_wrapper_p_dout, vau1_bram_wrapper_p_info[31:0]};
    // vau1_bram_wrapper outputs
    logic vau1_bram_wrapper_upstream_ready;
    logic [63:0] vau1_bram_wrapper_p_info;
    logic vau1_bram_wrapper_p_vld;
    logic [31:0] vau1_bram_wrapper_p_dout;
    single_cluster_bram_info_pipeline #(.INFO_WIDTH(64), .READ_LATENCY(2), .DOUT_WIDTH(32)) vau1_bram_wrapper (
        .clk(clk),
        .reset(reset),
        .info({dut_vecbuf1_t__unified_addr[126:125], dut_vecbuf1_t__unified_addr[29:0], dut_vecbuf1_t__unified_addr[63:32]}),
        // since write is enabled, we must ensure outgoing payloads are only valid if they originate from a read request
        .info_vld(dut_vecbuf1_t__unified_addr_vld && !dut_vecbuf1_t__unified_addr[127]),
        .downstream_ready(dut_vecbuf1_t__streaming_pld_rdy),
        .dout(vau1_bram_dout),
        //outputs
        .upstream_ready(vau1_bram_wrapper_upstream_ready),
        .p_info(vau1_bram_wrapper_p_info),
        .p_vld(vau1_bram_wrapper_p_vld),
        .p_dout(vau1_bram_wrapper_p_dout)
    ); 

    // pe0s_bram_wrapper BRAM address extraction
    assign pe0s_bram_addr = {3'b0, dut_pe0_t__unified_addr[124:96]};
    // pe0s_bram_wrapper enables
    assign pe0s_bram_wea = dut_pe0_t__unified_addr[127] && dut_pe0_t__unified_addr_vld;
    assign pe0s_bram_din = dut_pe0_t__unified_addr[95:64];
    assign pe0s_bram_enable = 1;
    // pe0s_bram_wrapper BRAM unified payload creation
    logic [127:0] pe0s_bram_wrapper_unified_pld;
    assign pe0s_bram_wrapper_unified_pld = {pe0s_bram_wrapper_p_info[95:0], pe0s_bram_wrapper_p_dout};
    // pe0s_bram_wrapper outputs
    logic pe0s_bram_wrapper_upstream_ready;
    logic [95:0] pe0s_bram_wrapper_p_info;
    logic pe0s_bram_wrapper_p_vld;
    logic [31:0] pe0s_bram_wrapper_p_dout;
    single_cluster_bram_info_pipeline #(.INFO_WIDTH(96), .READ_LATENCY(2), .DOUT_WIDTH(32)) pe0s_bram_wrapper (
        .clk(clk),
        .reset(reset),
        .info({dut_pe0_t__unified_addr[126:125], 1'b0, dut_pe0_t__unified_addr[124:96], dut_pe0_t__unified_addr[63:0]}),
        // since write is enabled, we must ensure outgoing payloads are only valid if they originate from a read request
        .info_vld(dut_pe0_t__unified_addr_vld && !dut_pe0_t__unified_addr[127]),
        .downstream_ready(dut_pe0_t__unified_pld_rdy),
        .dout(pe0s_bram_dout),
        //outputs
        .upstream_ready(pe0s_bram_wrapper_upstream_ready),
        .p_info(pe0s_bram_wrapper_p_info),
        .p_vld(pe0s_bram_wrapper_p_vld),
        .p_dout(pe0s_bram_wrapper_p_dout)
    );
    // pe0a_bram_wrapper BRAM address extraction
    assign pe0a_bram_addr = {3'b0, dut_pe0_t__accumulation_addr[124:96]};
    // pe0a_bram_wrapper enables
    assign pe0a_bram_wea = dut_pe0_t__accumulation_addr[127] && dut_pe0_t__accumulation_addr_vld;
    assign pe0a_bram_din = dut_pe0_t__accumulation_addr[95:64];
    assign pe0a_bram_enable = 1;
    // pe0a_bram_wrapper BRAM unified payload creation
    logic [127:0] pe0a_bram_wrapper_unified_pld;
    assign pe0a_bram_wrapper_unified_pld = '0; // akin to dummy payload, accumulations are purely writes hence we do not care to create this

    // pe1s_bram_wrapper BRAM address extraction
    assign pe1s_bram_addr = {3'b0, dut_pe1_t__unified_addr[124:96]};
    // pe1s_bram_wrapper enables
    assign pe1s_bram_wea = dut_pe1_t__unified_addr[127] && dut_pe1_t__unified_addr_vld;
    assign pe1s_bram_din = dut_pe1_t__unified_addr[95:64];
    assign pe1s_bram_enable = 1;
    // pe1s_bram_wrapper BRAM unified payload creation
    logic [127:0] pe1s_bram_wrapper_unified_pld;
    assign pe1s_bram_wrapper_unified_pld = {pe1s_bram_wrapper_p_info[95:0], pe1s_bram_wrapper_p_dout};
    // pe1s_bram_wrapper outputs
    logic pe1s_bram_wrapper_upstream_ready;
    logic [95:0] pe1s_bram_wrapper_p_info;
    logic pe1s_bram_wrapper_p_vld;
    logic [31:0] pe1s_bram_wrapper_p_dout;
    single_cluster_bram_info_pipeline #(.INFO_WIDTH(96), .READ_LATENCY(2), .DOUT_WIDTH(32)) pe1s_bram_wrapper (
        .clk(clk),
        .reset(reset),
        .info({dut_pe1_t__unified_addr[126:125], 1'b0, dut_pe1_t__unified_addr[124:96], dut_pe1_t__unified_addr[63:0]}),
        // since write is enabled, we must ensure outgoing payloads are only valid if they originate from a read request
        .info_vld(dut_pe1_t__unified_addr_vld && !dut_pe1_t__unified_addr[127]),
        .downstream_ready(dut_pe1_t__unified_pld_rdy),
        .dout(pe1s_bram_dout),
        //outputs
        .upstream_ready(pe1s_bram_wrapper_upstream_ready),
        .p_info(pe1s_bram_wrapper_p_info),
        .p_vld(pe1s_bram_wrapper_p_vld),
        .p_dout(pe1s_bram_wrapper_p_dout)
    );
    // pe1a_bram_wrapper BRAM address extraction
    assign pe1a_bram_addr = {3'b0, dut_pe1_t__accumulation_addr[124:96]};
    // pe1a_bram_wrapper enables
    assign pe1a_bram_wea = dut_pe1_t__accumulation_addr[127] && dut_pe1_t__accumulation_addr_vld;
    assign pe1a_bram_din = dut_pe1_t__accumulation_addr[95:64];
    assign pe1a_bram_enable = 1;
    // pe1a_bram_wrapper BRAM unified payload creation
    logic [127:0] pe1a_bram_wrapper_unified_pld;
    assign pe1a_bram_wrapper_unified_pld = '0; // akin to dummy payload, accumulations are purely writes hence we do not care to create this
endmodule
