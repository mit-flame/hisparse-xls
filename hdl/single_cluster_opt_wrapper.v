`timescale 1 ps / 1 ps

module single_cluster(
  input wire clk,
  input wire rst,

  // ML-send inputs/outputs
  input wire [31:0] t__cur_row_partition,
  input wire t__cur_row_partition_vld,
  input wire [31:0] t__num_col_partitions,
  input wire t__num_col_partitions_vld,
  input wire [31:0] t__tot_num_partitions,
  input wire t__tot_num_partitions_vld,
  input wire t__unified_addr_rdy,
  output wire [63:0] t__unified_addr,
  output wire t__unified_addr_vld,
  output wire t__cur_row_partition_rdy,
  output wire t__num_col_partitions_rdy,
  output wire t__tot_num_partitions_rdy,

  // ML-recv inputs/outputs
  input wire [159:0] t__unified_pld,
  input wire t__unified_pld_vld,
  output wire t__unified_pld_rdy,

  // VL inputs/outputs
  input wire t__hbm_vector_addr_rdy,
  input wire [63:0] t__hbm_vector_payload,
  input wire t__hbm_vector_payload_vld,
  input wire [31:0] t__num_matrix_cols,
  input wire t__num_matrix_cols_vld,
  output wire [31:0] t__hbm_vector_addr,
  output wire t__hbm_vector_addr_vld,
  output wire t__hbm_vector_payload_rdy,
  output wire t__num_matrix_cols_rdy,

  // VAU 0 inputs/outputs
  input wire [31:0] vecbuf0_t__num_col_partitions,
  input wire vecbuf0_t__num_col_partitions_vld,
  input wire vecbuf0_t__unified_addr_rdy,
  input wire [95:0] vecbuf0_t__streaming_pld,
  input wire vecbuf0_t__streaming_pld_vld,
  output wire vecbuf0_t__num_col_partitions_rdy,
  output wire [127:0] vecbuf0_t__unified_addr,
  output wire vecbuf0_t__unified_addr_vld,
  output wire vecbuf0_t__streaming_pld_rdy,

  // VAU 1 inputs/outputs
  input wire [31:0] vecbuf1_t__num_col_partitions,
  input wire vecbuf1_t__num_col_partitions_vld,
  input wire vecbuf1_t__unified_addr_rdy,
  input wire [95:0] vecbuf1_t__streaming_pld,
  input wire vecbuf1_t__streaming_pld_vld,
  output wire vecbuf1_t__num_col_partitions_rdy,
  output wire [127:0] vecbuf1_t__unified_addr,
  output wire vecbuf1_t__unified_addr_vld,
  output wire vecbuf1_t__streaming_pld_rdy,

  // PE0_send inputs/outputs
  input wire [29:0] pe0_t__num_rows_updated,
  input wire pe0_t__num_rows_updated_vld,
  output wire pe0_t__num_rows_updated_rdy,
  // PE0_arbiter inputs/outputs
  input wire pe0_t__unified_addr_rdy,
  output wire [127:0] pe0_t__unified_addr,
  output wire pe0_t__unified_addr_vld,
  // PE0_recv inputs/oututs
  input wire [31:0] pe0_t__stream_id,
  input wire pe0_t__stream_id_vld,
  input wire [127:0] pe0_t__unified_pld,
  input wire pe0_t__unified_pld_vld,
  input wire pe0_t__accumulation_addr_rdy,
  input wire [127:0] pe0_t__dummy_accumulate_pld,
  input wire pe0_t__dummy_accumulate_pld_vld,
  output wire pe0_t__stream_id_rdy,
  output wire pe0_t__unified_pld_rdy,
  output wire [127:0] pe0_t__accumulation_addr,
  output wire pe0_t__accumulation_addr_vld,

  // PE1_send inputs/outputs
  input wire [29:0] pe1_t__num_rows_updated,
  input wire pe1_t__num_rows_updated_vld,
  output wire pe1_t__num_rows_updated_rdy,
  // PE1_arbiter inputs/outputs
  input wire pe1_t__unified_addr_rdy,
  output wire [127:0] pe1_t__unified_addr,
  output wire pe1_t__unified_addr_vld,
  // PE1_recv inputs/oututs
  input wire [31:0] pe1_t__stream_id,
  input wire pe1_t__stream_id_vld,
  input wire [127:0] pe1_t__unified_pld,
  input wire pe1_t__unified_pld_vld,
  input wire pe1_t__accumulation_addr_rdy,
  input wire [127:0] pe1_t__dummy_accumulate_pld,
  input wire pe1_t__dummy_accumulate_pld_vld,
  output wire pe1_t__stream_id_rdy,
  output wire pe1_t__unified_pld_rdy,
  output wire [127:0] pe1_t__accumulation_addr,
  output wire pe1_t__accumulation_addr_vld,

  // kmerger inputs/outputs
  input wire [31:0] kmerger_t__current_row_partition,
  input wire kmerger_t__current_row_partition_vld,
  input wire kmerger_t__hbm_vector_addr_rdy,
  input wire kmerger_t__hbm_vector_payload_rdy,
  input wire [31:0] kmerger_t__num_hbm_channels_each_kernel,
  input wire kmerger_t__num_hbm_channels_each_kernel_vld,
  output wire kmerger_t__current_row_partition_rdy,
  output wire [31:0] kmerger_t__hbm_vector_addr,
  output wire kmerger_t__hbm_vector_addr_vld,
  output wire [63:0] kmerger_t__hbm_vector_payload,
  output wire kmerger_t__hbm_vector_payload_vld,
  output wire kmerger_t__num_hbm_channels_each_kernel_rdy
);

single_cluster_opt toplevel(
  .clk(clk),
  .rst(rst),

  // ML-send inputs/outputs
  .t__cur_row_partition(t__cur_row_partition),
  .t__cur_row_partition_vld(t__cur_row_partition_vld),
  .t__num_col_partitions(t__num_col_partitions),
  .t__num_col_partitions_vld(t__num_col_partitions_vld),
  .t__tot_num_partitions(t__tot_num_partitions),
  .t__tot_num_partitions_vld(t__tot_num_partitions_vld),
  .t__unified_addr_rdy(t__unified_addr_rdy),
  .t__unified_addr(t__unified_addr),
  .t__unified_addr_vld(t__unified_addr_vld),
  .t__cur_row_partition_rdy(t__cur_row_partition_rdy),
  .t__num_col_partitions_rdy(t__num_col_partitions_rdy),
  .t__tot_num_partitions_rdy(t__tot_num_partitions_rdy),

  // ML-recv inputs/outputs
  .t__unified_pld(t__unified_pld),
  .t__unified_pld_vld(t__unified_pld_vld),
  .t__unified_pld_rdy(t__unified_pld_rdy),

  // VL inputs/outputs
  .t__hbm_vector_addr_rdy(t__hbm_vector_addr_rdy),
  .t__hbm_vector_payload(t__hbm_vector_payload),
  .t__hbm_vector_payload_vld(t__hbm_vector_payload_vld),
  .t__num_matrix_cols(t__num_matrix_cols),
  .t__num_matrix_cols_vld(t__num_matrix_cols_vld),
  .t__hbm_vector_addr(t__hbm_vector_addr),
  .t__hbm_vector_addr_vld(t__hbm_vector_addr_vld),
  .t__hbm_vector_payload_rdy(t__hbm_vector_payload_rdy),
  .t__num_matrix_cols_rdy(t__num_matrix_cols_rdy),

  // VAU 0 inputs/outputs
  .vecbuf0_t__num_col_partitions(vecbuf0_t__num_col_partitions),
  .vecbuf0_t__num_col_partitions_vld(vecbuf0_t__num_col_partitions_vld),
  .vecbuf0_t__unified_addr_rdy(vecbuf0_t__unified_addr_rdy),
  .vecbuf0_t__streaming_pld(vecbuf0_t__streaming_pld),
  .vecbuf0_t__streaming_pld_vld(vecbuf0_t__streaming_pld_vld),
  .vecbuf0_t__num_col_partitions_rdy(vecbuf0_t__num_col_partitions_rdy),
  .vecbuf0_t__unified_addr(vecbuf0_t__unified_addr),
  .vecbuf0_t__unified_addr_vld(vecbuf0_t__unified_addr_vld),
  .vecbuf0_t__streaming_pld_rdy(vecbuf0_t__streaming_pld_rdy),

  // VAU 1 inputs/outputs
  .vecbuf1_t__num_col_partitions(vecbuf1_t__num_col_partitions),
  .vecbuf1_t__num_col_partitions_vld(vecbuf1_t__num_col_partitions_vld),
  .vecbuf1_t__unified_addr_rdy(vecbuf1_t__unified_addr_rdy),
  .vecbuf1_t__streaming_pld(vecbuf1_t__streaming_pld),
  .vecbuf1_t__streaming_pld_vld(vecbuf1_t__streaming_pld_vld),
  .vecbuf1_t__num_col_partitions_rdy(vecbuf1_t__num_col_partitions_rdy),
  .vecbuf1_t__unified_addr(vecbuf1_t__unified_addr),
  .vecbuf1_t__unified_addr_vld(vecbuf1_t__unified_addr_vld),
  .vecbuf1_t__streaming_pld_rdy(vecbuf1_t__streaming_pld_rdy),

  // PE0_send inputs/outputs
  .pe0_t__num_rows_updated(pe0_t__num_rows_updated),
  .pe0_t__num_rows_updated_vld(pe0_t__num_rows_updated_vld),
  .pe0_t__num_rows_updated_rdy(pe0_t__num_rows_updated_rdy),
  // PE0_arbiter inputs/outputs
  .pe0_t__unified_addr_rdy(pe0_t__unified_addr_rdy),
  .pe0_t__unified_addr(pe0_t__unified_addr),
  .pe0_t__unified_addr_vld(pe0_t__unified_addr_vld),
  // PE0_recv inputs/oututs
  .pe0_t__stream_id(pe0_t__stream_id),
  .pe0_t__stream_id_vld(pe0_t__stream_id_vld),
  .pe0_t__unified_pld(pe0_t__unified_pld),
  .pe0_t__unified_pld_vld(pe0_t__unified_pld_vld),
  .pe0_t__accumulation_addr_rdy(pe0_t__accumulation_addr_rdy),
  .pe0_t__dummy_accumulate_pld(pe0_t__dummy_accumulate_pld),
  .pe0_t__dummy_accumulate_pld_vld(pe0_t__dummy_accumulate_pld_vld),
  .pe0_t__stream_id_rdy(pe0_t__stream_id_rdy),
  .pe0_t__unified_pld_rdy(pe0_t__unified_pld_rdy),
  .pe0_t__accumulation_addr(pe0_t__accumulation_addr),
  .pe0_t__accumulation_addr_vld(pe0_t__accumulation_addr_vld),

  // PE1_send inputs/outputs
  .pe1_t__num_rows_updated(pe1_t__num_rows_updated),
  .pe1_t__num_rows_updated_vld(pe1_t__num_rows_updated_vld),
  .pe1_t__num_rows_updated_rdy(pe1_t__num_rows_updated_rdy),
  // PE1_arbiter inputs/outputs
  .pe1_t__unified_addr_rdy(pe1_t__unified_addr_rdy),
  .pe1_t__unified_addr(pe1_t__unified_addr),
  .pe1_t__unified_addr_vld(pe1_t__unified_addr_vld),
  // PE1_recv inputs/oututs
  .pe1_t__stream_id(pe1_t__stream_id),
  .pe1_t__stream_id_vld(pe1_t__stream_id_vld),
  .pe1_t__unified_pld(pe1_t__unified_pld),
  .pe1_t__unified_pld_vld(pe1_t__unified_pld_vld),
  .pe1_t__accumulation_addr_rdy(pe1_t__accumulation_addr_rdy),
  .pe1_t__dummy_accumulate_pld(pe1_t__dummy_accumulate_pld),
  .pe1_t__dummy_accumulate_pld_vld(pe1_t__dummy_accumulate_pld_vld),
  .pe1_t__stream_id_rdy(pe1_t__stream_id_rdy),
  .pe1_t__unified_pld_rdy(pe1_t__unified_pld_rdy),
  .pe1_t__accumulation_addr(pe1_t__accumulation_addr),
  .pe1_t__accumulation_addr_vld(pe1_t__accumulation_addr_vld),

  // kmerger inputs/outputs
  .kmerger_t__current_row_partition(kmerger_t__current_row_partition),
  .kmerger_t__current_row_partition_vld(kmerger_t__current_row_partition_vld),
  .kmerger_t__hbm_vector_addr_rdy(kmerger_t__hbm_vector_addr_rdy),
  .kmerger_t__hbm_vector_payload_rdy(kmerger_t__hbm_vector_payload_rdy),
  .kmerger_t__num_hbm_channels_each_kernel(kmerger_t__num_hbm_channels_each_kernel),
  .kmerger_t__num_hbm_channels_each_kernel_vld(kmerger_t__num_hbm_channels_each_kernel_vld),
  .kmerger_t__current_row_partition_rdy(kmerger_t__current_row_partition_rdy),
  .kmerger_t__hbm_vector_addr(kmerger_t__hbm_vector_addr),
  .kmerger_t__hbm_vector_addr_vld(kmerger_t__hbm_vector_addr_vld),
  .kmerger_t__hbm_vector_payload(kmerger_t__hbm_vector_payload),
  .kmerger_t__hbm_vector_payload_vld(kmerger_t__hbm_vector_payload_vld),
  .kmerger_t__num_hbm_channels_each_kernel_rdy(kmerger_t__num_hbm_channels_each_kernel_rdy)
);
endmodule
