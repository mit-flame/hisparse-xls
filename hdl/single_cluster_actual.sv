module single_cluster_actual(
  input wire clk,
  input wire rst,

  // ML inputs/outputs
  input wire [31:0] t__cur_row_partition,
  input wire t__cur_row_partition_vld,
  input wire [31:0] t__num_col_partitions,
  input wire t__num_col_partitions_vld,
  input wire [127:0] t__payload_type_one,
  input wire t__payload_type_one_vld,
  input wire t__payload_type_one_index_rdy,
  input wire [31:0] t__tot_num_partitions,
  input wire t__tot_num_partitions_vld,
  output wire t__cur_row_partition_rdy,
  output wire t__num_col_partitions_rdy,
  output wire t__payload_type_one_rdy,
  output wire [31:0] t__payload_type_one_index,
  output wire t__payload_type_one_index_vld,
  output wire t__tot_num_partitions_rdy,

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
  input wire vecbuf0_t__vecbuf_bank_addr_rdy,
  input wire [31:0] vecbuf0_t__vecbuf_din,
  input wire vecbuf0_t__vecbuf_din_vld,
  input wire vecbuf0_t__vecbuf_dout_rdy,
  output wire vecbuf0_t__num_col_partitions_rdy,
  output wire [31:0] vecbuf0_t__vecbuf_bank_addr,
  output wire vecbuf0_t__vecbuf_bank_addr_vld,
  output wire vecbuf0_t__vecbuf_din_rdy,
  output wire [31:0] vecbuf0_t__vecbuf_dout,
  output wire vecbuf0_t__vecbuf_dout_vld,

  // VAU 1 inputs/outputs
  input wire [31:0] vecbuf1_t__num_col_partitions,
  input wire vecbuf1_t__num_col_partitions_vld,
  input wire vecbuf1_t__vecbuf_bank_addr_rdy,
  input wire [31:0] vecbuf1_t__vecbuf_din,
  input wire vecbuf1_t__vecbuf_din_vld,
  input wire vecbuf1_t__vecbuf_dout_rdy,
  output wire vecbuf1_t__num_col_partitions_rdy,
  output wire [31:0] vecbuf1_t__vecbuf_bank_addr,
  output wire vecbuf1_t__vecbuf_bank_addr_vld,
  output wire vecbuf1_t__vecbuf_din_rdy,
  output wire [31:0] vecbuf1_t__vecbuf_dout,
  output wire vecbuf1_t__vecbuf_dout_vld,

  // PE 0 inputs/outputs
  input wire [29:0] pe0_t__num_rows_updated,
  input wire pe0_t__num_rows_updated_vld,
  input wire [31:0] pe0_t__stream_id,
  input wire pe0_t__stream_id_vld,
  input wire pe0_t__vecbuf_bank_addr_rdy,
  input wire [31:0] pe0_t__vecbuf_bank_din,
  input wire pe0_t__vecbuf_bank_din_vld,
  input wire pe0_t__vecbuf_bank_dout_rdy,
  output wire pe0_t__num_rows_updated_rdy,
  output wire pe0_t__stream_id_rdy,
  output wire [31:0] pe0_t__vecbuf_bank_addr,
  output wire pe0_t__vecbuf_bank_addr_vld,
  output wire pe0_t__vecbuf_bank_din_rdy,
  output wire [31:0] pe0_t__vecbuf_bank_dout,
  output wire pe0_t__vecbuf_bank_dout_vld,

  // PE 1 inputs/outputs
  input wire [29:0] pe1_t__num_rows_updated,
  input wire pe1_t__num_rows_updated_vld,
  input wire [31:0] pe1_t__stream_id,
  input wire pe1_t__stream_id_vld,
  input wire pe1_t__vecbuf_bank_addr_rdy,
  input wire [31:0] pe1_t__vecbuf_bank_din,
  input wire pe1_t__vecbuf_bank_din_vld,
  input wire pe1_t__vecbuf_bank_dout_rdy,
  output wire pe1_t__num_rows_updated_rdy,
  output wire pe1_t__stream_id_rdy,
  output wire [31:0] pe1_t__vecbuf_bank_addr,
  output wire pe1_t__vecbuf_bank_addr_vld,
  output wire pe1_t__vecbuf_bank_din_rdy,
  output wire [31:0] pe1_t__vecbuf_bank_dout,
  output wire pe1_t__vecbuf_bank_dout_vld,

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

  /*


  ML SIDE
  ------------------------------------------------------------------------------------------------------------------


  */
  logic [95:0] ml_t__multistream_payload_type_two__0;
  logic ml_t__multistream_payload_type_two__0_vld;
  logic [95:0] ml_t__multistream_payload_type_two__1;
  logic ml_t__multistream_payload_type_two__1_vld;
  __t__matrix_loader_0_next ml(
    .clk(clk),
    .rst(rst),
    .t__cur_row_partition(t__cur_row_partition),
    .t__cur_row_partition_vld(t__cur_row_partition_vld),
    .t__multistream_payload_type_two__0_rdy(sf_one_t__multistream_payload_type_two__0_rdy),
    .t__multistream_payload_type_two__1_rdy(sf_one_t__multistream_payload_type_two__1_rdy),
    .t__num_col_partitions(t__num_col_partitions),
    .t__num_col_partitions_vld(t__num_col_partitions_vld),
    .t__payload_type_one(t__payload_type_one),
    .t__payload_type_one_vld(t__payload_type_one_vld),
    .t__payload_type_one_index_rdy(t__payload_type_one_index_rdy),
    .t__tot_num_partitions(t__tot_num_partitions),
    .t__tot_num_partitions_vld(t__tot_num_partitions_vld),
    // outputs
    .t__cur_row_partition_rdy(t__cur_row_partition_rdy),
    .t__multistream_payload_type_two__0(ml_t__multistream_payload_type_two__0),
    .t__multistream_payload_type_two__0_vld(ml_t__multistream_payload_type_two__0_vld),
    .t__multistream_payload_type_two__1(ml_t__multistream_payload_type_two__1),
    .t__multistream_payload_type_two__1_vld(ml_t__multistream_payload_type_two__1_vld),
    .t__num_col_partitions_rdy(t__num_col_partitions_rdy),
    .t__payload_type_one_rdy(t__payload_type_one_rdy),
    .t__payload_type_one_index(t__payload_type_one_index),
    .t__payload_type_one_index_vld(t__payload_type_one_index_vld),
    .t__tot_num_partitions_rdy(t__tot_num_partitions_rdy)
  );

  logic arb_one_t__i_valid_rdy;
  logic [1:0] arb_one_t__original_input_valid;
  logic arb_one_t__original_input_valid_vld;
  logic [261:0] arb_one_t__combined_out;
  logic arb_one_t__combined_out_vld;
  logic arb_one_t__payload_rdy;
  logic arb_one_t__rotate_offset_rdy;

  __t__arbiter_wrapper_0_next arb_one(
    .clk(clk),
    .rst(rst),
    .t__combined_out_rdy(sfcore_one_t__combined_out_rdy),
    .t__i_valid(sfcore_one_t__i_valid),
    .t__i_valid_vld(sfcore_one_t__i_valid_vld),
    .t__payload(sfcore_one_t__payload),
    .t__payload_vld(sfcore_one_t__payload_vld),
    .t__rotate_offset(sfcore_one_t__rotate_offset),
    .t__rotate_offset_vld(sfcore_one_t__rotate_offset_vld),
    // outputs
    .t__combined_out(arb_one_t__combined_out),
    .t__combined_out_vld(arb_one_t__combined_out_vld),
    .t__i_valid_rdy(arb_one_t__i_valid_rdy),
    .t__payload_rdy(arb_one_t__payload_rdy),
    .t__rotate_offset_rdy(arb_one_t__rotate_offset_rdy)
  );

  logic [1:0] sfcore_one_t__i_valid;
  logic sfcore_one_t__i_valid_vld;
  logic [191:0] sfcore_one_t__payload;
  logic sfcore_one_t__payload_vld;
  logic [31:0] sfcore_one_t__rotate_offset;
  logic sfcore_one_t__rotate_offset_vld;
  logic sfcore_one_t__multistream_payload_i__0_rdy;
  logic sfcore_one_t__multistream_payload_i__1_rdy;
  logic [95:0] sfcore_one_t__multistream_payload_o__0;
  logic sfcore_one_t__multistream_payload_o__0_vld;
  logic [95:0] sfcore_one_t__multistream_payload_o__1;
  logic sfcore_one_t__multistream_payload_o__1_vld;
  logic sfcore_one_t__combined_out_rdy;

  __t__shuffler_core_0_next sf_core_one(
    .clk(clk),
    .rst(rst),
    .t__arbiter_combined_in(arb_one_t__combined_out),
    .t__arbiter_combined_in_vld(arb_one_t__combined_out_vld),
    .t__arbiter_i_valid_rdy(arb_one_t__i_valid_rdy),
    .t__arbiter_payload_type_two_i_rdy(arb_one_t__payload_rdy),
    .t__arbiter_rotate_offset_rdy(arb_one_t__rotate_offset_rdy),
    .t__multistream_payload_i__0(sf_one_t__multistream_payload_i__0),
    .t__multistream_payload_i__0_vld(sf_one_t__multistream_payload_i__0_vld),
    .t__multistream_payload_i__1(sf_one_t__multistream_payload_i__1),
    .t__multistream_payload_i__1_vld(sf_one_t__multistream_payload_i__1_vld),
    .t__multistream_payload_o__0_rdy(sf_one_t__shuffler_multistream__core_payload_o__0_rdy),
    .t__multistream_payload_o__1_rdy(sf_one_t__shuffler_multistream__core_payload_o__1_rdy),
    // outputs
    .t__arbiter_combined_in_rdy(sfcore_one_t__combined_out_rdy),
    .t__arbiter_i_valid(sfcore_one_t__i_valid),
    .t__arbiter_i_valid_vld(sfcore_one_t__i_valid_vld),
    .t__arbiter_payload_type_two_i(sfcore_one_t__payload),
    .t__arbiter_payload_type_two_i_vld(sfcore_one_t__payload_vld),
    .t__arbiter_rotate_offset(sfcore_one_t__rotate_offset),
    .t__arbiter_rotate_offset_vld(sfcore_one_t__rotate_offset_vld),
    .t__multistream_payload_i__0_rdy(sfcore_one_t__multistream_payload_i__0_rdy),
    .t__multistream_payload_i__1_rdy(sfcore_one_t__multistream_payload_i__1_rdy),
    .t__multistream_payload_o__0(sfcore_one_t__multistream_payload_o__0),
    .t__multistream_payload_o__0_vld(sfcore_one_t__multistream_payload_o__0_vld),
    .t__multistream_payload_o__1(sfcore_one_t__multistream_payload_o__1),
    .t__multistream_payload_o__1_vld(sfcore_one_t__multistream_payload_o__1_vld)
  );

  logic sf_one_t__multistream_payload_type_two__0_rdy;
  logic sf_one_t__multistream_payload_type_two__1_rdy;
  logic [95:0] sf_one_t__multistream_payload_i__0;
  logic sf_one_t__multistream_payload_i__0_vld;
  logic [95:0] sf_one_t__multistream_payload_i__1;
  logic sf_one_t__multistream_payload_i__1_vld;
  logic [95:0] sf_one_t__multistream_payload_o__0;
  logic sf_one_t__multistream_payload_o__0_vld;
  logic [95:0] sf_one_t__multistream_payload_o__1;
  logic sf_one_t__multistream_payload_o__1_vld;
  logic sf_one_t__shuffler_multistream__core_payload_o__0_rdy;
  logic sf_one_t__shuffler_multistream__core_payload_o__1_rdy;

  __t__shuffler_0_next sf_one(
    .clk(clk),
    .rst(rst),
    .t__multistream_payload_i__0(ml_t__multistream_payload_type_two__0),
    .t__multistream_payload_i__0_vld(ml_t__multistream_payload_type_two__0_vld),
    .t__multistream_payload_i__1(ml_t__multistream_payload_type_two__1),
    .t__multistream_payload_i__1_vld(ml_t__multistream_payload_type_two__1_vld),
    .t__multistream_payload_o__0_rdy(vecbuf0_t__multistream_payload_o__0_rdy),
    .t__multistream_payload_o__1_rdy(vecbuf1_t__multistream_payload_o__1_rdy),
    .t__shuffler_multistream__core_payload_i__0_rdy(sfcore_one_t__multistream_payload_i__0_rdy),
    .t__shuffler_multistream__core_payload_i__1_rdy(sfcore_one_t__multistream_payload_i__1_rdy),
    .t__shuffler_multistream__core_payload_o__0(sfcore_one_t__multistream_payload_o__0),
    .t__shuffler_multistream__core_payload_o__0_vld(sfcore_one_t__multistream_payload_o__0_vld),
    .t__shuffler_multistream__core_payload_o__1(sfcore_one_t__multistream_payload_o__1),
    .t__shuffler_multistream__core_payload_o__1_vld(sfcore_one_t__multistream_payload_o__1_vld),
    // outputs
    .t__multistream_payload_i__0_rdy(sf_one_t__multistream_payload_type_two__0_rdy),
    .t__multistream_payload_i__1_rdy(sf_one_t__multistream_payload_type_two__1_rdy),
    .t__multistream_payload_o__0(sf_one_t__multistream_payload_o__0),
    .t__multistream_payload_o__0_vld(sf_one_t__multistream_payload_o__0_vld),
    .t__multistream_payload_o__1(sf_one_t__multistream_payload_o__1),
    .t__multistream_payload_o__1_vld(sf_one_t__multistream_payload_o__1_vld),
    .t__shuffler_multistream__core_payload_i__0(sf_one_t__multistream_payload_i__0),
    .t__shuffler_multistream__core_payload_i__0_vld(sf_one_t__multistream_payload_i__0_vld),
    .t__shuffler_multistream__core_payload_i__1(sf_one_t__multistream_payload_i__1),
    .t__shuffler_multistream__core_payload_i__1_vld(sf_one_t__multistream_payload_i__1_vld),
    .t__shuffler_multistream__core_payload_o__0_rdy(sf_one_t__shuffler_multistream__core_payload_o__0_rdy),
    .t__shuffler_multistream__core_payload_o__1_rdy(sf_one_t__shuffler_multistream__core_payload_o__1_rdy)
  );


  /*


  ------------------------------------------------------------------------------------------------------------------


  */



  /*


  VL SIDE
  ------------------------------------------------------------------------------------------------------------------


  */

  logic [95:0] vl_t__vector_payload_one__0;
  logic vl_t__vector_payload_one__0_vld;

  __t__vector_loader_0_next vl(
    .clk(clk),
    .rst(rst),
    .t__hbm_vector_addr_rdy(t__hbm_vector_addr_rdy),
    .t__hbm_vector_payload(t__hbm_vector_payload),
    .t__hbm_vector_payload_vld(t__hbm_vector_payload_vld),
    .t__num_matrix_cols(t__num_matrix_cols),
    .t__num_matrix_cols_vld(t__num_matrix_cols_vld),
    .t__vector_payload_one__0_rdy(vunpacker_t__vector_payload_one_rdy),
    // outputs
    .t__hbm_vector_addr(t__hbm_vector_addr),
    .t__hbm_vector_addr_vld(t__hbm_vector_addr_vld),
    .t__hbm_vector_payload_rdy(t__hbm_vector_payload_rdy),
    .t__num_matrix_cols_rdy(t__num_matrix_cols_rdy),
    .t__vector_payload_one__0(vl_t__vector_payload_one__0),
    .t__vector_payload_one__0_vld(vl_t__vector_payload_one__0_vld)
  );


  logic [63:0] vunpacker_t__multistream_vector_payload_two__0;
  logic vunpacker_t__multistream_vector_payload_two__0_vld;
  logic [63:0] vunpacker_t__multistream_vector_payload_two__1;
  logic vunpacker_t__multistream_vector_payload_two__1_vld;
  logic vunpacker_t__vector_payload_one_rdy;

  __t__vector_unpacker_0_next vunpacker(
    .clk(clk),
    .rst(rst),
    .t__multistream_vector_payload_two__0_rdy(vecbuf0_t__multistream_vector_payload_two__0_rdy),
    .t__multistream_vector_payload_two__1_rdy(vecbuf1_t__multistream_vector_payload_two__1_rdy),
    .t__vector_payload_one(vl_t__vector_payload_one__0),
    .t__vector_payload_one_vld(vl_t__vector_payload_one__0_vld),
    // outputs
    .t__multistream_vector_payload_two__0(vunpacker_t__multistream_vector_payload_two__0),
    .t__multistream_vector_payload_two__0_vld(vunpacker_t__multistream_vector_payload_two__0_vld),
    .t__multistream_vector_payload_two__1(vunpacker_t__multistream_vector_payload_two__1),
    .t__multistream_vector_payload_two__1_vld(vunpacker_t__multistream_vector_payload_two__1_vld),
    .t__vector_payload_one_rdy(vunpacker_t__vector_payload_one_rdy)
  );


  /*


  ------------------------------------------------------------------------------------------------------------------


  */


  /*


  STREAM SIDE
  ------------------------------------------------------------------------------------------------------------------


  */
  

  /*
    STREAM ZERO==========================================>
  */
  logic vecbuf0_t__multistream_payload_o__0_rdy;
  logic vecbuf0_t__multistream_vector_payload_two__0_rdy;
  logic [95:0] vecbuf0_t__payload_type_three;
  logic vecbuf0_t__payload_type_three_vld;

  __t__vecbuf_access_unit_0_next vecbuf_zero(
    .clk(clk),
    .rst(rst),
    .t__matrix_payload_two(sf_one_t__multistream_payload_o__0),
    .t__matrix_payload_two_vld(sf_one_t__multistream_payload_o__0_vld),
    .t__num_col_partitions(vecbuf0_t__num_col_partitions),
    .t__num_col_partitions_vld(vecbuf0_t__num_col_partitions_vld),
    .t__payload_type_three_rdy(sf_two_t__multistream_payload_type_two__0_rdy),
    .t__vecbuf_bank_addr_rdy(vecbuf0_t__vecbuf_bank_addr_rdy),
    .t__vecbuf_din(vecbuf0_t__vecbuf_din),
    .t__vecbuf_din_vld(vecbuf0_t__vecbuf_din_vld),
    .t__vecbuf_dout_rdy(vecbuf0_t__vecbuf_dout_rdy),
    .t__vector_payload_two(vunpacker_t__multistream_vector_payload_two__0),
    .t__vector_payload_two_vld(vunpacker_t__multistream_vector_payload_two__0_vld),
    // outputs
    .t__matrix_payload_two_rdy(vecbuf0_t__multistream_payload_o__0_rdy),
    .t__num_col_partitions_rdy(vecbuf0_t__num_col_partitions_rdy),
    .t__payload_type_three(vecbuf0_t__payload_type_three),
    .t__payload_type_three_vld(vecbuf0_t__payload_type_three_vld),
    .t__vecbuf_bank_addr(vecbuf0_t__vecbuf_bank_addr),
    .t__vecbuf_bank_addr_vld(vecbuf0_t__vecbuf_bank_addr_vld),
    .t__vecbuf_din_rdy(vecbuf0_t__vecbuf_din_rdy),
    .t__vecbuf_dout(vecbuf0_t__vecbuf_dout),
    .t__vecbuf_dout_vld(vecbuf0_t__vecbuf_dout_vld),
    .t__vector_payload_two_rdy(vecbuf0_t__multistream_vector_payload_two__0_rdy)
  );
  // =============================================================>

  /*
    STREAM ONE=====================================================>
  */

  logic vecbuf1_t__multistream_payload_o__1_rdy;
  logic vecbuf1_t__multistream_vector_payload_two__1_rdy;
  logic [95:0] vecbuf1_t__payload_type_three;
  logic vecbuf1_t__payload_type_three_vld;

  __t__vecbuf_access_unit_0_next vecbuf_one(
    .clk(clk),
    .rst(rst),
    .t__matrix_payload_two(sf_one_t__multistream_payload_o__1),
    .t__matrix_payload_two_vld(sf_one_t__multistream_payload_o__1_vld),
    .t__num_col_partitions(vecbuf1_t__num_col_partitions),
    .t__num_col_partitions_vld(vecbuf1_t__num_col_partitions_vld),
    .t__payload_type_three_rdy(sf_two_t__multistream_payload_type_two__1_rdy),
    .t__vecbuf_bank_addr_rdy(vecbuf1_t__vecbuf_bank_addr_rdy),
    .t__vecbuf_din(vecbuf1_t__vecbuf_din),
    .t__vecbuf_din_vld(vecbuf1_t__vecbuf_din_vld),
    .t__vecbuf_dout_rdy(vecbuf1_t__vecbuf_dout_rdy),
    .t__vector_payload_two(vunpacker_t__multistream_vector_payload_two__1),
    .t__vector_payload_two_vld(vunpacker_t__multistream_vector_payload_two__1_vld),
    // outputs
    .t__matrix_payload_two_rdy(vecbuf1_t__multistream_payload_o__1_rdy),
    .t__num_col_partitions_rdy(vecbuf1_t__num_col_partitions_rdy),
    .t__payload_type_three(vecbuf1_t__payload_type_three),
    .t__payload_type_three_vld(vecbuf1_t__payload_type_three_vld),
    .t__vecbuf_bank_addr(vecbuf1_t__vecbuf_bank_addr),
    .t__vecbuf_bank_addr_vld(vecbuf1_t__vecbuf_bank_addr_vld),
    .t__vecbuf_din_rdy(vecbuf1_t__vecbuf_din_rdy),
    .t__vecbuf_dout(vecbuf1_t__vecbuf_dout),
    .t__vecbuf_dout_vld(vecbuf1_t__vecbuf_dout_vld),
    .t__vector_payload_two_rdy(vecbuf1_t__multistream_vector_payload_two__1_rdy)
  );

  // =============================================================>




  logic arb_two_t__i_valid_rdy;
  logic [1:0] arb_two_t__original_input_valid;
  logic arb_two_t__original_input_valid_vld;
  logic [261:0] arb_two_t__combined_out;
  logic arb_two_t__combined_out_vld;
  logic arb_two_t__payload_rdy;
  logic arb_two_t__rotate_offset_rdy;

  __t__arbiter_wrapper_0_next arb_two(
    .clk(clk),
    .rst(rst),
    .t__combined_out_rdy(sfcore_two_t__combined_out_rdy),
    .t__i_valid(sfcore_two_t__i_valid),
    .t__i_valid_vld(sfcore_two_t__i_valid_vld),
    .t__payload(sfcore_two_t__payload),
    .t__payload_vld(sfcore_two_t__payload_vld),
    .t__rotate_offset(sfcore_two_t__rotate_offset),
    .t__rotate_offset_vld(sfcore_two_t__rotate_offset_vld),
    // outputs
    .t__combined_out(arb_two_t__combined_out),
    .t__combined_out_vld(arb_two_t__combined_out_vld),
    .t__i_valid_rdy(arb_two_t__i_valid_rdy),
    .t__payload_rdy(arb_two_t__payload_rdy),
    .t__rotate_offset_rdy(arb_two_t__rotate_offset_rdy)
  );

  logic [1:0] sfcore_two_t__i_valid;
  logic sfcore_two_t__i_valid_vld;
  logic [191:0] sfcore_two_t__payload;
  logic sfcore_two_t__payload_vld;
  logic [31:0] sfcore_two_t__rotate_offset;
  logic sfcore_two_t__rotate_offset_vld;
  logic sfcore_two_t__multistream_payload_i__0_rdy;
  logic sfcore_two_t__multistream_payload_i__1_rdy;
  logic [95:0] sfcore_two_t__multistream_payload_o__0;
  logic sfcore_two_t__multistream_payload_o__0_vld;
  logic [95:0] sfcore_two_t__multistream_payload_o__1;
  logic sfcore_two_t__multistream_payload_o__1_vld;
  logic sfcore_two_t__combined_out_rdy;

  __t__shuffler_core_0_next sf_core_two(
    .clk(clk),
    .rst(rst),
    .t__arbiter_combined_in(arb_two_t__combined_out),
    .t__arbiter_combined_in_vld(arb_two_t__combined_out_vld),
    .t__arbiter_i_valid_rdy(arb_two_t__i_valid_rdy),
    .t__arbiter_payload_type_two_i_rdy(arb_two_t__payload_rdy),
    .t__arbiter_rotate_offset_rdy(arb_two_t__rotate_offset_rdy),
    .t__multistream_payload_i__0(sf_two_t__multistream_payload_i__0),
    .t__multistream_payload_i__0_vld(sf_two_t__multistream_payload_i__0_vld),
    .t__multistream_payload_i__1(sf_two_t__multistream_payload_i__1),
    .t__multistream_payload_i__1_vld(sf_two_t__multistream_payload_i__1_vld),
    .t__multistream_payload_o__0_rdy(sf_two_t__shuffler_multistream__core_payload_o__0_rdy),
    .t__multistream_payload_o__1_rdy(sf_two_t__shuffler_multistream__core_payload_o__1_rdy),
    // outputs
    .t__arbiter_combined_in_rdy(sfcore_two_t__combined_out_rdy),
    .t__arbiter_i_valid(sfcore_two_t__i_valid),
    .t__arbiter_i_valid_vld(sfcore_two_t__i_valid_vld),
    .t__arbiter_payload_type_two_i(sfcore_two_t__payload),
    .t__arbiter_payload_type_two_i_vld(sfcore_two_t__payload_vld),
    .t__arbiter_rotate_offset(sfcore_two_t__rotate_offset),
    .t__arbiter_rotate_offset_vld(sfcore_two_t__rotate_offset_vld),
    .t__multistream_payload_i__0_rdy(sfcore_two_t__multistream_payload_i__0_rdy),
    .t__multistream_payload_i__1_rdy(sfcore_two_t__multistream_payload_i__1_rdy),
    .t__multistream_payload_o__0(sfcore_two_t__multistream_payload_o__0),
    .t__multistream_payload_o__0_vld(sfcore_two_t__multistream_payload_o__0_vld),
    .t__multistream_payload_o__1(sfcore_two_t__multistream_payload_o__1),
    .t__multistream_payload_o__1_vld(sfcore_two_t__multistream_payload_o__1_vld)
  );


  logic sf_two_t__multistream_payload_type_two__0_rdy;
  logic sf_two_t__multistream_payload_type_two__1_rdy;
  logic [95:0] sf_two_t__multistream_payload_i__0;
  logic sf_two_t__multistream_payload_i__0_vld;
  logic [95:0] sf_two_t__multistream_payload_i__1;
  logic sf_two_t__multistream_payload_i__1_vld;
  logic [95:0] sf_two_t__multistream_payload_o__0;
  logic sf_two_t__multistream_payload_o__0_vld;
  logic [95:0] sf_two_t__multistream_payload_o__1;
  logic sf_two_t__multistream_payload_o__1_vld;
  logic sf_two_t__shuffler_multistream__core_payload_o__0_rdy;
  logic sf_two_t__shuffler_multistream__core_payload_o__1_rdy;
  logic sf_two_t__multistream_payload_o__1_rdy;

  __t__shuffler_0_next sf_two(
    .clk(clk),
    .rst(rst),
    .t__multistream_payload_i__0(vecbuf0_t__payload_type_three),
    .t__multistream_payload_i__0_vld(vecbuf0_t__payload_type_three_vld),
    .t__multistream_payload_i__1(vecbuf1_t__payload_type_three),
    .t__multistream_payload_i__1_vld(vecbuf1_t__payload_type_three_vld),
    .t__multistream_payload_o__0_rdy(pe0_t__payload_type_three_rdy),
    .t__multistream_payload_o__1_rdy(pe1_t__payload_type_three_rdy),
    .t__shuffler_multistream__core_payload_i__0_rdy(sfcore_two_t__multistream_payload_i__0_rdy),
    .t__shuffler_multistream__core_payload_i__1_rdy(sfcore_two_t__multistream_payload_i__1_rdy),
    .t__shuffler_multistream__core_payload_o__0(sfcore_two_t__multistream_payload_o__0),
    .t__shuffler_multistream__core_payload_o__0_vld(sfcore_two_t__multistream_payload_o__0_vld),
    .t__shuffler_multistream__core_payload_o__1(sfcore_two_t__multistream_payload_o__1),
    .t__shuffler_multistream__core_payload_o__1_vld(sfcore_two_t__multistream_payload_o__1_vld),
    // outputs
    .t__multistream_payload_i__0_rdy(sf_two_t__multistream_payload_type_two__0_rdy),
    .t__multistream_payload_i__1_rdy(sf_two_t__multistream_payload_type_two__1_rdy),
    .t__multistream_payload_o__0(sf_two_t__multistream_payload_o__0),
    .t__multistream_payload_o__0_vld(sf_two_t__multistream_payload_o__0_vld),
    .t__multistream_payload_o__1(sf_two_t__multistream_payload_o__1),
    .t__multistream_payload_o__1_vld(sf_two_t__multistream_payload_o__1_vld),
    .t__shuffler_multistream__core_payload_i__0(sf_two_t__multistream_payload_i__0),
    .t__shuffler_multistream__core_payload_i__0_vld(sf_two_t__multistream_payload_i__0_vld),
    .t__shuffler_multistream__core_payload_i__1(sf_two_t__multistream_payload_i__1),
    .t__shuffler_multistream__core_payload_i__1_vld(sf_two_t__multistream_payload_i__1_vld),
    .t__shuffler_multistream__core_payload_o__0_rdy(sf_two_t__shuffler_multistream__core_payload_o__0_rdy),
    .t__shuffler_multistream__core_payload_o__1_rdy(sf_two_t__shuffler_multistream__core_payload_o__1_rdy)
  );

    logic [63:0] pe0_t__payload_type_four;
    logic pe0_t__payload_type_four_vld;
    logic pe0_t__payload_type_three_rdy;

  __t__processing_engine_0_next pe0 (
    .clk(clk),
    .rst(rst),
    .t__num_rows_updated(pe0_t__num_rows_updated),
    .t__num_rows_updated_vld(pe0_t__num_rows_updated_vld),
    .t__payload_type_four_rdy(cpacker_t__payload_type_four__0_rdy),
    .t__payload_type_three(sf_two_t__multistream_payload_o__0),
    .t__payload_type_three_vld(sf_two_t__multistream_payload_o__0_vld),
    .t__stream_id(pe0_t__stream_id),
    .t__stream_id_vld(pe0_t__stream_id_vld),
    .t__vecbuf_bank_addr_rdy(pe0_t__vecbuf_bank_addr_rdy),
    .t__vecbuf_bank_din(pe0_t__vecbuf_bank_din),
    .t__vecbuf_bank_din_vld(pe0_t__vecbuf_bank_din_vld),
    .t__vecbuf_bank_dout_rdy(pe0_t__vecbuf_bank_dout_rdy),
    
    .t__num_rows_updated_rdy(pe0_t__num_rows_updated_rdy),
    .t__payload_type_four(pe0_t__payload_type_four),
    .t__payload_type_four_vld(pe0_t__payload_type_four_vld),
    .t__payload_type_three_rdy(pe0_t__payload_type_three_rdy),
    .t__stream_id_rdy(pe0_t__stream_id_rdy),
    .t__vecbuf_bank_addr(pe0_t__vecbuf_bank_addr),
    .t__vecbuf_bank_addr_vld(pe0_t__vecbuf_bank_addr_vld),
    .t__vecbuf_bank_din_rdy(pe0_t__vecbuf_bank_din_rdy),
    .t__vecbuf_bank_dout(pe0_t__vecbuf_bank_dout),
    .t__vecbuf_bank_dout_vld(pe0_t__vecbuf_bank_dout_vld)
    );

    logic [63:0] pe1_t__payload_type_four;
    logic pe1_t__payload_type_four_vld;
    logic pe1_t__payload_type_three_rdy;

  __t__processing_engine_0_next pe1 (
    .clk(clk),
    .rst(rst),
    .t__num_rows_updated(pe1_t__num_rows_updated),
    .t__num_rows_updated_vld(pe1_t__num_rows_updated_vld),
    .t__payload_type_four_rdy(cpacker_t__payload_type_four__1_rdy),
    .t__payload_type_three(sf_two_t__multistream_payload_o__1),
    .t__payload_type_three_vld(sf_two_t__multistream_payload_o__1_vld),
    .t__stream_id(pe1_t__stream_id),
    .t__stream_id_vld(pe1_t__stream_id_vld),
    .t__vecbuf_bank_addr_rdy(pe1_t__vecbuf_bank_addr_rdy),
    .t__vecbuf_bank_din(pe1_t__vecbuf_bank_din),
    .t__vecbuf_bank_din_vld(pe1_t__vecbuf_bank_din_vld),
    .t__vecbuf_bank_dout_rdy(pe1_t__vecbuf_bank_dout_rdy),
    // outputs
    .t__num_rows_updated_rdy(pe1_t__num_rows_updated_rdy),
    .t__payload_type_four(pe1_t__payload_type_four),
    .t__payload_type_four_vld(pe1_t__payload_type_four_vld),
    .t__payload_type_three_rdy(pe1_t__payload_type_three_rdy),
    .t__stream_id_rdy(pe1_t__stream_id_rdy),
    .t__vecbuf_bank_addr(pe1_t__vecbuf_bank_addr),
    .t__vecbuf_bank_addr_vld(pe1_t__vecbuf_bank_addr_vld),
    .t__vecbuf_bank_din_rdy(pe1_t__vecbuf_bank_din_rdy),
    .t__vecbuf_bank_dout(pe1_t__vecbuf_bank_dout),
    .t__vecbuf_bank_dout_vld(pe1_t__vecbuf_bank_dout_vld)
  );

    logic cpacker_t__payload_type_four__0_rdy;
    logic cpacker_t__payload_type_four__1_rdy;
    logic [95:0] cpacker_t__vector_payload_one;
    logic cpacker_t__vector_payload_one_vld;

  __t__cluster_packer_0_next cpacker(
    .clk(clk),
    .rst(rst),
    .t__payload_type_four__0(pe0_t__payload_type_four),
    .t__payload_type_four__0_vld(pe0_t__payload_type_four_vld),
    .t__payload_type_four__1(pe1_t__payload_type_four),
    .t__payload_type_four__1_vld(pe1_t__payload_type_four_vld),
    .t__vector_payload_one_rdy(cmerger_t__multistream_vector_payload_one__0_rdy),
    // outputs
    .t__payload_type_four__0_rdy(cpacker_t__payload_type_four__0_rdy),
    .t__payload_type_four__1_rdy(cpacker_t__payload_type_four__1_rdy),
    .t__vector_payload_one(cpacker_t__vector_payload_one),
    .t__vector_payload_one_vld(cpacker_t__vector_payload_one_vld)
  );

    logic cmerger_t__multistream_vector_payload_one__0_rdy;
    logic [95:0] cmerger_t__vector_payload_one;
    logic cmerger_t__vector_payload_one_vld;
  __t__clusters_results_merger_0_next cmerger(
    .clk(clk),
    .rst(rst),
    .t__multistream_vector_payload_one__0(cpacker_t__vector_payload_one),
    .t__multistream_vector_payload_one__0_vld(cpacker_t__vector_payload_one_vld),
    .t__vector_payload_one_rdy(kmerger_t__multikernel_vector_payload_one__0_rdy),
    // outline
    .t__multistream_vector_payload_one__0_rdy(cmerger_t__multistream_vector_payload_one__0_rdy),
    .t__vector_payload_one(cmerger_t__vector_payload_one),
    .t__vector_payload_one_vld(cmerger_t__vector_payload_one_vld)
  );

  logic kmerger_t__multikernel_vector_payload_one__0_rdy;

__t__kernels_results_merger_0_next kmerger(
  .clk(clk),
  .rst(rst),
  .t__current_row_partition(kmerger_t__current_row_partition),
  .t__current_row_partition_vld(kmerger_t__current_row_partition_vld),
  .t__hbm_vector_addr_rdy(kmerger_t__hbm_vector_addr_rdy),
  .t__hbm_vector_payload_rdy(kmerger_t__hbm_vector_payload_rdy),
  .t__multikernel_vector_payload_one__0(cmerger_t__vector_payload_one),
  .t__multikernel_vector_payload_one__0_vld(cmerger_t__vector_payload_one_vld),
  .t__num_hbm_channels_each_kernel(kmerger_t__num_hbm_channels_each_kernel),
  .t__num_hbm_channels_each_kernel_vld(kmerger_t__num_hbm_channels_each_kernel_vld),
  // outputs
  .t__current_row_partition_rdy(kmerger_t__current_row_partition_rdy),
  .t__hbm_vector_addr(kmerger_t__hbm_vector_addr),
  .t__hbm_vector_addr_vld(kmerger_t__hbm_vector_addr_vld),
  .t__hbm_vector_payload(kmerger_t__hbm_vector_payload),
  .t__hbm_vector_payload_vld(kmerger_t__hbm_vector_payload_vld),
  .t__multikernel_vector_payload_one__0_rdy(kmerger_t__multikernel_vector_payload_one__0_rdy),
  .t__num_hbm_channels_each_kernel_rdy(kmerger_t__num_hbm_channels_each_kernel_rdy)
);

endmodule
