`default_nettype none
module __t__matrix_loader_recv_0_next(
  input wire clk,
  input wire rst,
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
  wire [159:0] __t__streaming_payload_one_reg_init = {{64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000}, 2'h0, 30'h0000_0000};
  reg [30:0] ____state_0_1_1;
  reg ____state_0_1_0;
  reg [30:0] ____state_0_0_1;
  reg ____state_0_0_0;
  reg __t__multistream_payload_type_two__0_has_been_sent_reg;
  reg __t__multistream_payload_type_two__1_has_been_sent_reg;
  reg [159:0] __t__streaming_payload_one_reg;
  reg __t__streaming_payload_one_valid_reg;
  reg [95:0] __t__multistream_payload_type_two__0_reg;
  reg __t__multistream_payload_type_two__0_valid_reg;
  reg [95:0] __t__multistream_payload_type_two__1_reg;
  reg __t__multistream_payload_type_two__1_valid_reg;
  wire [63:0] payload_one[2];
  wire [63:0] array_index_473;
  wire [63:0] array_index_477;
  wire [31:0] index;
  wire [31:0] index__1;
  wire __t__multistream_payload_type_two__0_not_has_been_sent;
  wire t__multistream_payload_type_two__0_valid_inv;
  wire __t__multistream_payload_type_two__1_not_has_been_sent;
  wire t__multistream_payload_type_two__1_valid_inv;
  wire [1:0] commands;
  wire next_row_marker_predicate;
  wire next_row_marker_predicate__1;
  wire __t__multistream_payload_type_two__0_valid_and_not_has_been_sent;
  wire t__multistream_payload_type_two__0_valid_load_en;
  wire __t__multistream_payload_type_two__1_valid_and_not_has_been_sent;
  wire t__multistream_payload_type_two__1_valid_load_en;
  wire eq_474;
  wire t__multistream_payload_type_two__0_load_en;
  wire t__multistream_payload_type_two__1_load_en;
  wire [1:0] ____state_0_0_1__next_value_predicates;
  wire [1:0] ____state_0_1_1__next_value_predicates;
  wire __t__multistream_payload_type_two__0_has_sent_or_is_ready;
  wire __t__multistream_payload_type_two__1_has_sent_or_is_ready;
  wire [31:0] sel_490;
  wire [2:0] one_hot_518;
  wire [2:0] one_hot_519;
  wire p0_all_active_outputs_ready;
  wire [30:0] and_486;
  wire p0_stage_done;
  wire [30:0] add_493;
  wire [31:0] data;
  wire [30:0] add_506;
  wire [31:0] data__1;
  wire t__streaming_payload_one_valid_inv;
  wire [29:0] pld_index;
  wire nor_502;
  wire [31:0] pld_data;
  wire [29:0] pld_index__1;
  wire bit_slice_516;
  wire [31:0] pld_data__1;
  wire t__streaming_payload_one_valid_load_en;
  wire ____state_0_0_1__at_most_one_next_value;
  wire ____state_0_1_1__at_most_one_next_value;
  wire [1:0] concat_550;
  wire [1:0] concat_557;
  wire __t__multistream_payload_type_two__0_valid_and_all_active_outputs_ready;
  wire __t__multistream_payload_type_two__0_valid_and_ready_txfr;
  wire __t__multistream_payload_type_two__1_valid_and_ready_txfr;
  wire ne_511;
  wire [95:0] concat_513;
  wire t__streaming_payload_one_load_en;
  wire or_630;
  wire or_632;
  wire [30:0] one_hot_sel_551;
  wire [30:0] one_hot_sel_558;
  wire __t__multistream_payload_type_two__0_not_stage_load;
  wire __t__multistream_payload_type_two__0_has_been_sent_reg_load_en;
  wire __t__multistream_payload_type_two__1_has_been_sent_reg_load_en;
  wire [95:0] outgoing_payload_two;
  wire [95:0] outgoing_payload_two__1;
  assign payload_one[0] = __t__streaming_payload_one_reg[95:32];
  assign payload_one[1] = __t__streaming_payload_one_reg[159:96];
  assign array_index_473 = payload_one[1'h0];
  assign array_index_477 = payload_one[1'h1];
  assign index = array_index_473[63:32];
  assign index__1 = array_index_477[63:32];
  assign __t__multistream_payload_type_two__0_not_has_been_sent = ~__t__multistream_payload_type_two__0_has_been_sent_reg;
  assign t__multistream_payload_type_two__0_valid_inv = ~__t__multistream_payload_type_two__0_valid_reg;
  assign __t__multistream_payload_type_two__1_not_has_been_sent = ~__t__multistream_payload_type_two__1_has_been_sent_reg;
  assign t__multistream_payload_type_two__1_valid_inv = ~__t__multistream_payload_type_two__1_valid_reg;
  assign commands = __t__streaming_payload_one_reg[31:30];
  assign next_row_marker_predicate = index == 32'hffff_ffff;
  assign next_row_marker_predicate__1 = index__1 == 32'hffff_ffff;
  assign __t__multistream_payload_type_two__0_valid_and_not_has_been_sent = __t__streaming_payload_one_valid_reg & __t__multistream_payload_type_two__0_not_has_been_sent;
  assign t__multistream_payload_type_two__0_valid_load_en = t__multistream_payload_type_two__0_rdy | t__multistream_payload_type_two__0_valid_inv;
  assign __t__multistream_payload_type_two__1_valid_and_not_has_been_sent = __t__streaming_payload_one_valid_reg & __t__multistream_payload_type_two__1_not_has_been_sent;
  assign t__multistream_payload_type_two__1_valid_load_en = t__multistream_payload_type_two__1_rdy | t__multistream_payload_type_two__1_valid_inv;
  assign eq_474 = commands == 2'h1;
  assign t__multistream_payload_type_two__0_load_en = __t__multistream_payload_type_two__0_valid_and_not_has_been_sent & t__multistream_payload_type_two__0_valid_load_en;
  assign t__multistream_payload_type_two__1_load_en = __t__multistream_payload_type_two__1_valid_and_not_has_been_sent & t__multistream_payload_type_two__1_valid_load_en;
  assign ____state_0_0_1__next_value_predicates = {~next_row_marker_predicate, next_row_marker_predicate};
  assign ____state_0_1_1__next_value_predicates = {~next_row_marker_predicate__1, next_row_marker_predicate__1};
  assign __t__multistream_payload_type_two__0_has_sent_or_is_ready = t__multistream_payload_type_two__0_load_en | __t__multistream_payload_type_two__0_has_been_sent_reg;
  assign __t__multistream_payload_type_two__1_has_sent_or_is_ready = t__multistream_payload_type_two__1_load_en | __t__multistream_payload_type_two__1_has_been_sent_reg;
  assign sel_490 = eq_474 ? 32'h0000_0001 : {____state_0_1_1, ____state_0_1_0};
  assign one_hot_518 = {____state_0_0_1__next_value_predicates[1:0] == 2'h0, ____state_0_0_1__next_value_predicates[1] && !____state_0_0_1__next_value_predicates[0], ____state_0_0_1__next_value_predicates[0]};
  assign one_hot_519 = {____state_0_1_1__next_value_predicates[1:0] == 2'h0, ____state_0_1_1__next_value_predicates[1] && !____state_0_1_1__next_value_predicates[0], ____state_0_1_1__next_value_predicates[0]};
  assign p0_all_active_outputs_ready = __t__multistream_payload_type_two__0_has_sent_or_is_ready & __t__multistream_payload_type_two__1_has_sent_or_is_ready;
  assign and_486 = ____state_0_0_1 & {31{~eq_474}};
  assign p0_stage_done = __t__streaming_payload_one_valid_reg & p0_all_active_outputs_ready;
  assign add_493 = and_486 + array_index_473[30:0];
  assign data = array_index_473[31:0];
  assign add_506 = sel_490[31:1] + array_index_477[30:0];
  assign data__1 = array_index_477[31:0];
  assign t__streaming_payload_one_valid_inv = ~__t__streaming_payload_one_valid_reg;
  assign pld_index = array_index_473[61:32] & {30{~next_row_marker_predicate}};
  assign nor_502 = ~(eq_474 | ~____state_0_0_0);
  assign pld_data = data & {32{~next_row_marker_predicate}};
  assign pld_index__1 = array_index_477[61:32] & {30{~next_row_marker_predicate__1}};
  assign bit_slice_516 = sel_490[0];
  assign pld_data__1 = data__1 & {32{~next_row_marker_predicate__1}};
  assign t__streaming_payload_one_valid_load_en = p0_stage_done | t__streaming_payload_one_valid_inv;
  assign ____state_0_0_1__at_most_one_next_value = ~next_row_marker_predicate == one_hot_518[1] & next_row_marker_predicate == one_hot_518[0];
  assign ____state_0_1_1__at_most_one_next_value = ~next_row_marker_predicate__1 == one_hot_519[1] & next_row_marker_predicate__1 == one_hot_519[0];
  assign concat_550 = {~next_row_marker_predicate & p0_stage_done, next_row_marker_predicate & p0_stage_done};
  assign concat_557 = {~next_row_marker_predicate__1 & p0_stage_done, next_row_marker_predicate__1 & p0_stage_done};
  assign __t__multistream_payload_type_two__0_valid_and_all_active_outputs_ready = __t__streaming_payload_one_valid_reg & p0_all_active_outputs_ready;
  assign __t__multistream_payload_type_two__0_valid_and_ready_txfr = __t__multistream_payload_type_two__0_valid_and_not_has_been_sent & t__multistream_payload_type_two__0_load_en;
  assign __t__multistream_payload_type_two__1_valid_and_ready_txfr = __t__multistream_payload_type_two__1_valid_and_not_has_been_sent & t__multistream_payload_type_two__1_load_en;
  assign ne_511 = commands != 2'h0;
  assign concat_513 = {commands, 94'h0000_0000_0000_0000_0000_0000};
  assign t__streaming_payload_one_load_en = t__streaming_payload_one_vld & t__streaming_payload_one_valid_load_en;
  assign or_630 = ~p0_stage_done | ____state_0_0_1__at_most_one_next_value | rst;
  assign or_632 = ~p0_stage_done | ____state_0_1_1__at_most_one_next_value | rst;
  assign one_hot_sel_551 = add_493 & {31{concat_550[0]}} | and_486 & {31{concat_550[1]}};
  assign one_hot_sel_558 = add_506 & {31{concat_557[0]}} | sel_490[31:1] & {31{concat_557[1]}};
  assign __t__multistream_payload_type_two__0_not_stage_load = ~__t__multistream_payload_type_two__0_valid_and_all_active_outputs_ready;
  assign __t__multistream_payload_type_two__0_has_been_sent_reg_load_en = __t__multistream_payload_type_two__0_valid_and_ready_txfr | __t__multistream_payload_type_two__0_valid_and_all_active_outputs_ready;
  assign __t__multistream_payload_type_two__1_has_been_sent_reg_load_en = __t__multistream_payload_type_two__1_valid_and_ready_txfr | __t__multistream_payload_type_two__0_valid_and_all_active_outputs_ready;
  assign outgoing_payload_two = ne_511 ? concat_513 : {2'h0, pld_index, next_row_marker_predicate ? add_493 : ____state_0_0_1, nor_502, pld_data};
  assign outgoing_payload_two__1 = ne_511 ? concat_513 : {2'h0, pld_index__1, next_row_marker_predicate__1 ? add_506 : sel_490[31:1], bit_slice_516, pld_data__1};
  always_ff @ (posedge clk) begin
    if (rst) begin
      ____state_0_1_1 <= 31'h0000_0000;
      ____state_0_1_0 <= 1'h0;
      ____state_0_0_1 <= 31'h0000_0000;
      ____state_0_0_0 <= 1'h0;
      __t__multistream_payload_type_two__0_has_been_sent_reg <= 1'h0;
      __t__multistream_payload_type_two__1_has_been_sent_reg <= 1'h0;
      __t__streaming_payload_one_reg <= __t__streaming_payload_one_reg_init;
      __t__streaming_payload_one_valid_reg <= 1'h0;
      __t__multistream_payload_type_two__0_reg <= 96'h0000_0000_0000_0000_0000_0000;
      __t__multistream_payload_type_two__0_valid_reg <= 1'h0;
      __t__multistream_payload_type_two__1_reg <= 96'h0000_0000_0000_0000_0000_0000;
      __t__multistream_payload_type_two__1_valid_reg <= 1'h0;
    end else begin
      ____state_0_1_1 <= p0_stage_done ? one_hot_sel_558 : ____state_0_1_1;
      ____state_0_1_0 <= p0_stage_done ? bit_slice_516 : ____state_0_1_0;
      ____state_0_0_1 <= p0_stage_done ? one_hot_sel_551 : ____state_0_0_1;
      ____state_0_0_0 <= p0_stage_done ? nor_502 : ____state_0_0_0;
      __t__multistream_payload_type_two__0_has_been_sent_reg <= __t__multistream_payload_type_two__0_has_been_sent_reg_load_en ? __t__multistream_payload_type_two__0_not_stage_load : __t__multistream_payload_type_two__0_has_been_sent_reg;
      __t__multistream_payload_type_two__1_has_been_sent_reg <= __t__multistream_payload_type_two__1_has_been_sent_reg_load_en ? __t__multistream_payload_type_two__0_not_stage_load : __t__multistream_payload_type_two__1_has_been_sent_reg;
      __t__streaming_payload_one_reg <= t__streaming_payload_one_load_en ? t__streaming_payload_one : __t__streaming_payload_one_reg;
      __t__streaming_payload_one_valid_reg <= t__streaming_payload_one_valid_load_en ? t__streaming_payload_one_vld : __t__streaming_payload_one_valid_reg;
      __t__multistream_payload_type_two__0_reg <= t__multistream_payload_type_two__0_load_en ? outgoing_payload_two : __t__multistream_payload_type_two__0_reg;
      __t__multistream_payload_type_two__0_valid_reg <= t__multistream_payload_type_two__0_valid_load_en ? __t__multistream_payload_type_two__0_valid_and_not_has_been_sent : __t__multistream_payload_type_two__0_valid_reg;
      __t__multistream_payload_type_two__1_reg <= t__multistream_payload_type_two__1_load_en ? outgoing_payload_two__1 : __t__multistream_payload_type_two__1_reg;
      __t__multistream_payload_type_two__1_valid_reg <= t__multistream_payload_type_two__1_valid_load_en ? __t__multistream_payload_type_two__1_valid_and_not_has_been_sent : __t__multistream_payload_type_two__1_valid_reg;
    end
  end
  assign t__multistream_payload_type_two__0 = __t__multistream_payload_type_two__0_reg;
  assign t__multistream_payload_type_two__0_vld = __t__multistream_payload_type_two__0_valid_reg;
  assign t__multistream_payload_type_two__1 = __t__multistream_payload_type_two__1_reg;
  assign t__multistream_payload_type_two__1_vld = __t__multistream_payload_type_two__1_valid_reg;
  assign t__streaming_payload_one_rdy = t__streaming_payload_one_load_en;
  `ifdef ASSERT_ON
  ____state_0_0_1__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_630))) or_630) else $fatal(0, "More than one next_value fired for state element: __state_0_0_1");
  ____state_0_1_1__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_632))) or_632) else $fatal(0, "More than one next_value fired for state element: __state_0_1_1");
  `endif  // ASSERT_ON
endmodule
`default_nettype wire
