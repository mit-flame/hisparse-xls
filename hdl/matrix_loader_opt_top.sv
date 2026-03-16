module matrix_loader_opt_top(
  input wire clk,
  input wire rst,

  // ML-send inputs/outputs
  input wire [31:0] t__cur_row_partition,
  input wire t__cur_row_partition_vld,
  input wire t__metadata_addr_rdy,
  input wire [127:0] t__metadata_payload,
  input wire t__metadata_payload_vld,
  input wire [31:0] t__num_col_partitions,
  input wire t__num_col_partitions_vld,
  input wire t__streaming_addr_rdy,
  input wire [31:0] t__tot_num_partitions,
  input wire t__tot_num_partitions_vld,
  output wire t__cur_row_partition_rdy,
  output wire [31:0] t__metadata_addr,
  output wire t__metadata_addr_vld,
  output wire t__metadata_payload_rdy,
  output wire t__num_col_partitions_rdy,
  output wire [63:0] t__streaming_addr,
  output wire t__streaming_addr_vld,
  output wire t__tot_num_partitions_rdy,

  // ML-recv inputs/outputs
  input wire t__multistream_payload_type_two__0_rdy,
  input wire t__multistream_payload_type_two__1_rdy,
  input wire [159:0] t__streaming_payload_one,
  input wire t__streaming_payload_one_vld,
  output wire [95:0] t__multistream_payload_type_two__0,
  output wire t__multistream_payload_type_two__0_vld,
  output wire [95:0] t__multistream_payload_type_two__1,
  output wire t__multistream_payload_type_two__1_vld,
  output wire t__streaming_payload_one_rdy
);

__t__matrix_loader_send_0_next mlsend(
  .clk(clk),
  .rst(rst),
  .t__cur_row_partition(t__cur_row_partition),
  .t__cur_row_partition_vld(t__cur_row_partition_vld),
  .t__metadata_addr_rdy(t__metadata_addr_rdy),
  .t__metadata_payload(t__metadata_payload),
  .t__metadata_payload_vld(t__metadata_payload_vld),
  .t__num_col_partitions(t__num_col_partitions),
  .t__num_col_partitions_vld(t__num_col_partitions_vld),
  .t__streaming_addr_rdy(t__streaming_addr_rdy),
  .t__tot_num_partitions(t__tot_num_partitions),
  .t__tot_num_partitions_vld(t__tot_num_partitions_vld),
  // outputs
  .t__cur_row_partition_rdy(t__cur_row_partition_rdy),
  .t__metadata_addr(t__metadata_addr),
  .t__metadata_addr_vld(t__metadata_addr_vld),
  .t__metadata_payload_rdy(t__metadata_payload_rdy),
  .t__num_col_partitions_rdy(t__num_col_partitions_rdy),
  .t__streaming_addr(t__streaming_addr),
  .t__streaming_addr_vld(t__streaming_addr_vld),
  .t__tot_num_partitions_rdy(t__tot_num_partitions_rdy)
);

__t__matrix_loader_recv_0_next mlrecv(
  .clk(clk),
  .rst(rst),
  .t__multistream_payload_type_two__0_rdy(t__multistream_payload_type_two__0_rdy),
  .t__multistream_payload_type_two__1_rdy(t__multistream_payload_type_two__1_rdy),
  .t__streaming_payload_one(t__streaming_payload_one),
  .t__streaming_payload_one_vld(t__streaming_payload_one_vld),

  .t__multistream_payload_type_two__0(t__multistream_payload_type_two__0),
  .t__multistream_payload_type_two__0_vld(t__multistream_payload_type_two__0_vld),
  .t__multistream_payload_type_two__1(t__multistream_payload_type_two__1),
  .t__multistream_payload_type_two__1_vld(t__multistream_payload_type_two__1_vld),
  .t__streaming_payload_one_rdy(t__streaming_payload_one_rdy)
);

endmodule
