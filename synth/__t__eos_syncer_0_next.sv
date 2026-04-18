`default_nettype none
module __t__eos_syncer_0_next(
  input wire clk,
  input wire rst,
  input wire [95:0] t__multistream_payload_i__0,
  input wire t__multistream_payload_i__0_vld,
  input wire [95:0] t__multistream_payload_i__1,
  input wire t__multistream_payload_i__1_vld,
  input wire t__multistream_payload_o__0_rdy,
  input wire t__multistream_payload_o__1_rdy,
  output wire t__multistream_payload_i__0_rdy,
  output wire t__multistream_payload_i__1_rdy,
  output wire [95:0] t__multistream_payload_o__0,
  output wire t__multistream_payload_o__0_vld,
  output wire [95:0] t__multistream_payload_o__1,
  output wire t__multistream_payload_o__1_vld
);
  reg ____state_0_0;
  reg ____state_0_1;
  reg __t__multistream_payload_o__0_has_been_sent_reg;
  reg __t__multistream_payload_o__1_has_been_sent_reg;
  reg [95:0] __t__multistream_payload_i__0_reg;
  reg __t__multistream_payload_i__0_valid_reg;
  reg [95:0] __t__multistream_payload_i__1_reg;
  reg __t__multistream_payload_i__1_valid_reg;
  reg [95:0] __t__multistream_payload_o__0_reg;
  reg __t__multistream_payload_o__0_valid_reg;
  reg [95:0] __t__multistream_payload_o__1_reg;
  reg __t__multistream_payload_o__1_valid_reg;
  wire recv;
  wire recv__1;
  wire t__multistream_payload_o__0_valid_inv;
  wire t__multistream_payload_o__1_valid_inv;
  wire __t__multistream_payload_o__0_not_has_been_sent;
  wire t__multistream_payload_o__0_valid_load_en;
  wire __t__multistream_payload_o__1_not_has_been_sent;
  wire t__multistream_payload_o__1_valid_load_en;
  wire [95:0] t__multistream_payload_i__0_select;
  wire [95:0] t__multistream_payload_i__1_select;
  wire t__multistream_payload_o__0_load_en;
  wire t__multistream_payload_o__1_load_en;
  wire __t__multistream_payload_o__0_has_sent_or_is_ready;
  wire __t__multistream_payload_o__1_has_sent_or_is_ready;
  wire eq_403;
  wire eq_404;
  wire p0_all_active_outputs_ready;
  wire or_406;
  wire or_407;
  wire t__multistream_payload_i__0_valid_inv;
  wire t__multistream_payload_i__1_valid_inv;
  wire and_410;
  wire t__multistream_payload_i__0_valid_load_en;
  wire t__multistream_payload_i__1_valid_load_en;
  wire __t__multistream_payload_o__0_valid_and_ready_txfr;
  wire __t__multistream_payload_o__1_valid_and_ready_txfr;
  wire [95:0] spld__1;
  wire [95:0] spld__3;
  wire t__multistream_payload_i__0_load_en;
  wire t__multistream_payload_i__1_load_en;
  wire and_420;
  wire and_421;
  wire __t__multistream_payload_o__0_not_stage_load;
  wire __t__multistream_payload_o__0_has_been_sent_reg_load_en;
  wire __t__multistream_payload_o__1_has_been_sent_reg_load_en;
  wire [95:0] opld;
  wire [95:0] opld__1;
  assign recv = ~____state_0_0;
  assign recv__1 = ~____state_0_1;
  assign t__multistream_payload_o__0_valid_inv = ~__t__multistream_payload_o__0_valid_reg;
  assign t__multistream_payload_o__1_valid_inv = ~__t__multistream_payload_o__1_valid_reg;
  assign __t__multistream_payload_o__0_not_has_been_sent = ~__t__multistream_payload_o__0_has_been_sent_reg;
  assign t__multistream_payload_o__0_valid_load_en = t__multistream_payload_o__0_rdy | t__multistream_payload_o__0_valid_inv;
  assign __t__multistream_payload_o__1_not_has_been_sent = ~__t__multistream_payload_o__1_has_been_sent_reg;
  assign t__multistream_payload_o__1_valid_load_en = t__multistream_payload_o__1_rdy | t__multistream_payload_o__1_valid_inv;
  assign t__multistream_payload_i__0_select = recv & __t__multistream_payload_i__0_valid_reg ? __t__multistream_payload_i__0_reg : 96'h0000_0000_0000_0000_0000_0000;
  assign t__multistream_payload_i__1_select = recv__1 & __t__multistream_payload_i__1_valid_reg ? __t__multistream_payload_i__1_reg : 96'h0000_0000_0000_0000_0000_0000;
  assign t__multistream_payload_o__0_load_en = __t__multistream_payload_o__0_not_has_been_sent & t__multistream_payload_o__0_valid_load_en;
  assign t__multistream_payload_o__1_load_en = __t__multistream_payload_o__1_not_has_been_sent & t__multistream_payload_o__1_valid_load_en;
  assign __t__multistream_payload_o__0_has_sent_or_is_ready = t__multistream_payload_o__0_load_en | __t__multistream_payload_o__0_has_been_sent_reg;
  assign __t__multistream_payload_o__1_has_sent_or_is_ready = t__multistream_payload_o__1_load_en | __t__multistream_payload_o__1_has_been_sent_reg;
  assign eq_403 = t__multistream_payload_i__0_select[95:94] == 2'h3;
  assign eq_404 = t__multistream_payload_i__1_select[95:94] == 2'h3;
  assign p0_all_active_outputs_ready = __t__multistream_payload_o__0_has_sent_or_is_ready & __t__multistream_payload_o__1_has_sent_or_is_ready;
  assign or_406 = eq_403 | ____state_0_0;
  assign or_407 = eq_404 | ____state_0_1;
  assign t__multistream_payload_i__0_valid_inv = ~__t__multistream_payload_i__0_valid_reg;
  assign t__multistream_payload_i__1_valid_inv = ~__t__multistream_payload_i__1_valid_reg;
  assign and_410 = or_406 & or_407;
  assign t__multistream_payload_i__0_valid_load_en = p0_all_active_outputs_ready & recv | t__multistream_payload_i__0_valid_inv;
  assign t__multistream_payload_i__1_valid_load_en = p0_all_active_outputs_ready & recv__1 | t__multistream_payload_i__1_valid_inv;
  assign __t__multistream_payload_o__0_valid_and_ready_txfr = __t__multistream_payload_o__0_not_has_been_sent & t__multistream_payload_o__0_load_en;
  assign __t__multistream_payload_o__1_valid_and_ready_txfr = __t__multistream_payload_o__1_not_has_been_sent & t__multistream_payload_o__1_load_en;
  assign spld__1 = t__multistream_payload_i__0_select & {96{~eq_403}};
  assign spld__3 = t__multistream_payload_i__1_select & {96{~eq_404}};
  assign t__multistream_payload_i__0_load_en = t__multistream_payload_i__0_vld & t__multistream_payload_i__0_valid_load_en;
  assign t__multistream_payload_i__1_load_en = t__multistream_payload_i__1_vld & t__multistream_payload_i__1_valid_load_en;
  assign and_420 = ~and_410 & or_406;
  assign and_421 = ~and_410 & or_407;
  assign __t__multistream_payload_o__0_not_stage_load = ~p0_all_active_outputs_ready;
  assign __t__multistream_payload_o__0_has_been_sent_reg_load_en = __t__multistream_payload_o__0_valid_and_ready_txfr | p0_all_active_outputs_ready;
  assign __t__multistream_payload_o__1_has_been_sent_reg_load_en = __t__multistream_payload_o__1_valid_and_ready_txfr | p0_all_active_outputs_ready;
  assign opld = and_410 ? 96'hc000_0000_0000_0000_0000_0000 : spld__1;
  assign opld__1 = and_410 ? 96'hc000_0000_0000_0000_0000_0000 : spld__3;
  always_ff @ (posedge clk) begin
    if (rst) begin
      ____state_0_0 <= 1'h0;
      ____state_0_1 <= 1'h0;
      __t__multistream_payload_o__0_has_been_sent_reg <= 1'h0;
      __t__multistream_payload_o__1_has_been_sent_reg <= 1'h0;
      __t__multistream_payload_i__0_reg <= 96'h0000_0000_0000_0000_0000_0000;
      __t__multistream_payload_i__0_valid_reg <= 1'h0;
      __t__multistream_payload_i__1_reg <= 96'h0000_0000_0000_0000_0000_0000;
      __t__multistream_payload_i__1_valid_reg <= 1'h0;
      __t__multistream_payload_o__0_reg <= 96'h0000_0000_0000_0000_0000_0000;
      __t__multistream_payload_o__0_valid_reg <= 1'h0;
      __t__multistream_payload_o__1_reg <= 96'h0000_0000_0000_0000_0000_0000;
      __t__multistream_payload_o__1_valid_reg <= 1'h0;
    end else begin
      ____state_0_0 <= p0_all_active_outputs_ready ? and_420 : ____state_0_0;
      ____state_0_1 <= p0_all_active_outputs_ready ? and_421 : ____state_0_1;
      __t__multistream_payload_o__0_has_been_sent_reg <= __t__multistream_payload_o__0_has_been_sent_reg_load_en ? __t__multistream_payload_o__0_not_stage_load : __t__multistream_payload_o__0_has_been_sent_reg;
      __t__multistream_payload_o__1_has_been_sent_reg <= __t__multistream_payload_o__1_has_been_sent_reg_load_en ? __t__multistream_payload_o__0_not_stage_load : __t__multistream_payload_o__1_has_been_sent_reg;
      __t__multistream_payload_i__0_reg <= t__multistream_payload_i__0_load_en ? t__multistream_payload_i__0 : __t__multistream_payload_i__0_reg;
      __t__multistream_payload_i__0_valid_reg <= t__multistream_payload_i__0_valid_load_en ? t__multistream_payload_i__0_vld : __t__multistream_payload_i__0_valid_reg;
      __t__multistream_payload_i__1_reg <= t__multistream_payload_i__1_load_en ? t__multistream_payload_i__1 : __t__multistream_payload_i__1_reg;
      __t__multistream_payload_i__1_valid_reg <= t__multistream_payload_i__1_valid_load_en ? t__multistream_payload_i__1_vld : __t__multistream_payload_i__1_valid_reg;
      __t__multistream_payload_o__0_reg <= t__multistream_payload_o__0_load_en ? opld : __t__multistream_payload_o__0_reg;
      __t__multistream_payload_o__0_valid_reg <= t__multistream_payload_o__0_valid_load_en ? __t__multistream_payload_o__0_not_has_been_sent : __t__multistream_payload_o__0_valid_reg;
      __t__multistream_payload_o__1_reg <= t__multistream_payload_o__1_load_en ? opld__1 : __t__multistream_payload_o__1_reg;
      __t__multistream_payload_o__1_valid_reg <= t__multistream_payload_o__1_valid_load_en ? __t__multistream_payload_o__1_not_has_been_sent : __t__multistream_payload_o__1_valid_reg;
    end
  end
  assign t__multistream_payload_i__0_rdy = t__multistream_payload_i__0_load_en;
  assign t__multistream_payload_i__1_rdy = t__multistream_payload_i__1_load_en;
  assign t__multistream_payload_o__0 = __t__multistream_payload_o__0_reg;
  assign t__multistream_payload_o__0_vld = __t__multistream_payload_o__0_valid_reg;
  assign t__multistream_payload_o__1 = __t__multistream_payload_o__1_reg;
  assign t__multistream_payload_o__1_vld = __t__multistream_payload_o__1_valid_reg;
endmodule
`default_nettype wire
