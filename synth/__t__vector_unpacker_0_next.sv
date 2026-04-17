module __t__vector_unpacker_0_next(
  input wire clk,
  input wire rst,
  input wire t__multistream_vector_payload_two__0_rdy,
  input wire t__multistream_vector_payload_two__1_rdy,
  input wire [95:0] t__vector_payload_one,
  input wire t__vector_payload_one_vld,
  output wire [63:0] t__multistream_vector_payload_two__0,
  output wire t__multistream_vector_payload_two__0_vld,
  output wire [63:0] t__multistream_vector_payload_two__1,
  output wire t__multistream_vector_payload_two__1_vld,
  output wire t__vector_payload_one_rdy
);
  reg p0_valid;
  reg p1_valid;
  reg __t__multistream_vector_payload_two__0_has_been_sent_reg;
  reg __t__multistream_vector_payload_two__1_has_been_sent_reg;
  reg [95:0] __t__vector_payload_one_reg;
  reg __t__vector_payload_one_valid_reg;
  reg [63:0] __t__multistream_vector_payload_two__0_reg;
  reg __t__multistream_vector_payload_two__0_valid_reg;
  reg [63:0] __t__multistream_vector_payload_two__1_reg;
  reg __t__multistream_vector_payload_two__1_valid_reg;
  wire __t__multistream_vector_payload_two__0_not_has_been_sent;
  wire t__multistream_vector_payload_two__0_valid_inv;
  wire __t__multistream_vector_payload_two__1_not_has_been_sent;
  wire t__multistream_vector_payload_two__1_valid_inv;
  wire __t__multistream_vector_payload_two__0_valid_and_not_has_been_sent;
  wire t__multistream_vector_payload_two__0_valid_load_en;
  wire __t__multistream_vector_payload_two__1_valid_and_not_has_been_sent;
  wire t__multistream_vector_payload_two__1_valid_load_en;
  wire t__multistream_vector_payload_two__0_load_en;
  wire t__multistream_vector_payload_two__1_load_en;
  wire __t__multistream_vector_payload_two__0_has_sent_or_is_ready;
  wire __t__multistream_vector_payload_two__1_has_sent_or_is_ready;
  wire p0_all_active_outputs_ready;
  wire p0_stage_done;
  wire t__vector_payload_one_valid_inv;
  wire t__vector_payload_one_valid_load_en;
  wire __t__multistream_vector_payload_two__0_valid_and_all_active_outputs_ready;
  wire __t__multistream_vector_payload_two__0_valid_and_ready_txfr;
  wire __t__multistream_vector_payload_two__1_valid_and_ready_txfr;
  wire t__vector_payload_one_load_en;
  wire p1_enable;
  wire p0_enable;
  wire __t__multistream_vector_payload_two__0_not_stage_load;
  wire __t__multistream_vector_payload_two__0_has_been_sent_reg_load_en;
  wire __t__multistream_vector_payload_two__1_has_been_sent_reg_load_en;
  wire [63:0] __t__multistream_vector_payload_two__0_buf;
  wire [63:0] __t__multistream_vector_payload_two__1_buf;
  assign __t__multistream_vector_payload_two__0_not_has_been_sent = ~__t__multistream_vector_payload_two__0_has_been_sent_reg;
  assign t__multistream_vector_payload_two__0_valid_inv = ~__t__multistream_vector_payload_two__0_valid_reg;
  assign __t__multistream_vector_payload_two__1_not_has_been_sent = ~__t__multistream_vector_payload_two__1_has_been_sent_reg;
  assign t__multistream_vector_payload_two__1_valid_inv = ~__t__multistream_vector_payload_two__1_valid_reg;
  assign __t__multistream_vector_payload_two__0_valid_and_not_has_been_sent = __t__vector_payload_one_valid_reg & __t__multistream_vector_payload_two__0_not_has_been_sent;
  assign t__multistream_vector_payload_two__0_valid_load_en = t__multistream_vector_payload_two__0_rdy | t__multistream_vector_payload_two__0_valid_inv;
  assign __t__multistream_vector_payload_two__1_valid_and_not_has_been_sent = __t__vector_payload_one_valid_reg & __t__multistream_vector_payload_two__1_not_has_been_sent;
  assign t__multistream_vector_payload_two__1_valid_load_en = t__multistream_vector_payload_two__1_rdy | t__multistream_vector_payload_two__1_valid_inv;
  assign t__multistream_vector_payload_two__0_load_en = __t__multistream_vector_payload_two__0_valid_and_not_has_been_sent & t__multistream_vector_payload_two__0_valid_load_en;
  assign t__multistream_vector_payload_two__1_load_en = __t__multistream_vector_payload_two__1_valid_and_not_has_been_sent & t__multistream_vector_payload_two__1_valid_load_en;
  assign __t__multistream_vector_payload_two__0_has_sent_or_is_ready = t__multistream_vector_payload_two__0_load_en | __t__multistream_vector_payload_two__0_has_been_sent_reg;
  assign __t__multistream_vector_payload_two__1_has_sent_or_is_ready = t__multistream_vector_payload_two__1_load_en | __t__multistream_vector_payload_two__1_has_been_sent_reg;
  assign p0_all_active_outputs_ready = __t__multistream_vector_payload_two__0_has_sent_or_is_ready & __t__multistream_vector_payload_two__1_has_sent_or_is_ready;
  assign p0_stage_done = __t__vector_payload_one_valid_reg & p0_all_active_outputs_ready;
  assign t__vector_payload_one_valid_inv = ~__t__vector_payload_one_valid_reg;
  assign t__vector_payload_one_valid_load_en = p0_stage_done | t__vector_payload_one_valid_inv;
  assign __t__multistream_vector_payload_two__0_valid_and_all_active_outputs_ready = __t__vector_payload_one_valid_reg & p0_all_active_outputs_ready;
  assign __t__multistream_vector_payload_two__0_valid_and_ready_txfr = __t__multistream_vector_payload_two__0_valid_and_not_has_been_sent & t__multistream_vector_payload_two__0_load_en;
  assign __t__multistream_vector_payload_two__1_valid_and_ready_txfr = __t__multistream_vector_payload_two__1_valid_and_not_has_been_sent & t__multistream_vector_payload_two__1_load_en;
  assign t__vector_payload_one_load_en = t__vector_payload_one_vld & t__vector_payload_one_valid_load_en;
  assign p1_enable = 1'h1;
  assign p0_enable = 1'h1;
  assign __t__multistream_vector_payload_two__0_not_stage_load = ~__t__multistream_vector_payload_two__0_valid_and_all_active_outputs_ready;
  assign __t__multistream_vector_payload_two__0_has_been_sent_reg_load_en = __t__multistream_vector_payload_two__0_valid_and_ready_txfr | __t__multistream_vector_payload_two__0_valid_and_all_active_outputs_ready;
  assign __t__multistream_vector_payload_two__1_has_been_sent_reg_load_en = __t__multistream_vector_payload_two__1_valid_and_ready_txfr | __t__multistream_vector_payload_two__0_valid_and_all_active_outputs_ready;
  assign __t__multistream_vector_payload_two__0_buf = {__t__vector_payload_one_reg[95:94], __t__vector_payload_one_reg[92:64], 1'h0, __t__vector_payload_one_reg[31:0]};
  assign __t__multistream_vector_payload_two__1_buf = {__t__vector_payload_one_reg[95:94], __t__vector_payload_one_reg[92:64], 1'h1, __t__vector_payload_one_reg[63:32]};
  always_ff @ (posedge clk) begin
    if (rst) begin
      p0_valid <= 1'h0;
      p1_valid <= 1'h0;
      __t__multistream_vector_payload_two__0_has_been_sent_reg <= 1'h0;
      __t__multistream_vector_payload_two__1_has_been_sent_reg <= 1'h0;
      __t__vector_payload_one_reg <= 96'h0000_0000_0000_0000_0000_0000;
      __t__vector_payload_one_valid_reg <= 1'h0;
      __t__multistream_vector_payload_two__0_reg <= 64'h0000_0000_0000_0000;
      __t__multistream_vector_payload_two__0_valid_reg <= 1'h0;
      __t__multistream_vector_payload_two__1_reg <= 64'h0000_0000_0000_0000;
      __t__multistream_vector_payload_two__1_valid_reg <= 1'h0;
    end else begin
      p0_valid <= p0_enable ? p0_stage_done : p0_valid;
      p1_valid <= p1_enable ? p0_valid : p1_valid;
      __t__multistream_vector_payload_two__0_has_been_sent_reg <= __t__multistream_vector_payload_two__0_has_been_sent_reg_load_en ? __t__multistream_vector_payload_two__0_not_stage_load : __t__multistream_vector_payload_two__0_has_been_sent_reg;
      __t__multistream_vector_payload_two__1_has_been_sent_reg <= __t__multistream_vector_payload_two__1_has_been_sent_reg_load_en ? __t__multistream_vector_payload_two__0_not_stage_load : __t__multistream_vector_payload_two__1_has_been_sent_reg;
      __t__vector_payload_one_reg <= t__vector_payload_one_load_en ? t__vector_payload_one : __t__vector_payload_one_reg;
      __t__vector_payload_one_valid_reg <= t__vector_payload_one_valid_load_en ? t__vector_payload_one_vld : __t__vector_payload_one_valid_reg;
      __t__multistream_vector_payload_two__0_reg <= t__multistream_vector_payload_two__0_load_en ? __t__multistream_vector_payload_two__0_buf : __t__multistream_vector_payload_two__0_reg;
      __t__multistream_vector_payload_two__0_valid_reg <= t__multistream_vector_payload_two__0_valid_load_en ? __t__multistream_vector_payload_two__0_valid_and_not_has_been_sent : __t__multistream_vector_payload_two__0_valid_reg;
      __t__multistream_vector_payload_two__1_reg <= t__multistream_vector_payload_two__1_load_en ? __t__multistream_vector_payload_two__1_buf : __t__multistream_vector_payload_two__1_reg;
      __t__multistream_vector_payload_two__1_valid_reg <= t__multistream_vector_payload_two__1_valid_load_en ? __t__multistream_vector_payload_two__1_valid_and_not_has_been_sent : __t__multistream_vector_payload_two__1_valid_reg;
    end
  end
  assign t__multistream_vector_payload_two__0 = __t__multistream_vector_payload_two__0_reg;
  assign t__multistream_vector_payload_two__0_vld = __t__multistream_vector_payload_two__0_valid_reg;
  assign t__multistream_vector_payload_two__1 = __t__multistream_vector_payload_two__1_reg;
  assign t__multistream_vector_payload_two__1_vld = __t__multistream_vector_payload_two__1_valid_reg;
  assign t__vector_payload_one_rdy = t__vector_payload_one_load_en;
endmodule
