module __t__matrix_loader_pld_arbiter_0_next(
  input wire clk,
  input wire rst,
  input wire t__metadata_pld_rdy,
  input wire t__streaming_pld_rdy,
  input wire [159:0] t__unified_pld,
  input wire t__unified_pld_vld,
  output wire [159:0] t__metadata_pld,
  output wire t__metadata_pld_vld,
  output wire [159:0] t__streaming_pld,
  output wire t__streaming_pld_vld,
  output wire t__unified_pld_rdy
);
  wire [159:0] __t__unified_pld_reg_init = {{64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000}, 2'h0, 30'h0000_0000};
  wire [159:0] __t__metadata_pld_reg_init = {{64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000}, 2'h0, 30'h0000_0000};
  wire [159:0] __t__streaming_pld_reg_init = {{64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000}, 2'h0, 30'h0000_0000};
  reg p0_valid;
  reg p1_valid;
  reg [159:0] __t__unified_pld_reg;
  reg __t__unified_pld_valid_reg;
  reg [159:0] __t__metadata_pld_reg;
  reg __t__metadata_pld_valid_reg;
  reg [159:0] __t__streaming_pld_reg;
  reg __t__streaming_pld_valid_reg;
  wire [29:0] upld_message_type;
  wire eq_65;
  wire t__metadata_pld_valid_inv;
  wire eq_66;
  wire t__streaming_pld_valid_inv;
  wire __t__metadata_pld_vld_buf;
  wire t__metadata_pld_valid_load_en;
  wire __t__streaming_pld_vld_buf;
  wire t__streaming_pld_valid_load_en;
  wire t__metadata_pld_not_pred;
  wire t__metadata_pld_load_en;
  wire t__streaming_pld_not_pred;
  wire t__streaming_pld_load_en;
  wire p0_all_active_outputs_ready;
  wire p0_stage_done;
  wire t__unified_pld_valid_inv;
  wire t__unified_pld_valid_load_en;
  wire t__unified_pld_load_en;
  wire p1_enable;
  wire p0_enable;
  assign upld_message_type = __t__unified_pld_reg[29:0];
  assign eq_65 = upld_message_type == 30'h0000_0000;
  assign t__metadata_pld_valid_inv = ~__t__metadata_pld_valid_reg;
  assign eq_66 = upld_message_type == 30'h0000_0001;
  assign t__streaming_pld_valid_inv = ~__t__streaming_pld_valid_reg;
  assign __t__metadata_pld_vld_buf = __t__unified_pld_valid_reg & eq_65;
  assign t__metadata_pld_valid_load_en = t__metadata_pld_rdy | t__metadata_pld_valid_inv;
  assign __t__streaming_pld_vld_buf = __t__unified_pld_valid_reg & eq_66;
  assign t__streaming_pld_valid_load_en = t__streaming_pld_rdy | t__streaming_pld_valid_inv;
  assign t__metadata_pld_not_pred = ~eq_65;
  assign t__metadata_pld_load_en = __t__metadata_pld_vld_buf & t__metadata_pld_valid_load_en;
  assign t__streaming_pld_not_pred = ~eq_66;
  assign t__streaming_pld_load_en = __t__streaming_pld_vld_buf & t__streaming_pld_valid_load_en;
  assign p0_all_active_outputs_ready = (t__metadata_pld_not_pred | t__metadata_pld_load_en) & (t__streaming_pld_not_pred | t__streaming_pld_load_en);
  assign p0_stage_done = __t__unified_pld_valid_reg & p0_all_active_outputs_ready;
  assign t__unified_pld_valid_inv = ~__t__unified_pld_valid_reg;
  assign t__unified_pld_valid_load_en = p0_stage_done | t__unified_pld_valid_inv;
  assign t__unified_pld_load_en = t__unified_pld_vld & t__unified_pld_valid_load_en;
  assign p1_enable = 1'h1;
  assign p0_enable = 1'h1;
  always_ff @ (posedge clk) begin
    if (rst) begin
      p0_valid <= 1'h0;
      p1_valid <= 1'h0;
      __t__unified_pld_reg <= __t__unified_pld_reg_init;
      __t__unified_pld_valid_reg <= 1'h0;
      __t__metadata_pld_reg <= __t__metadata_pld_reg_init;
      __t__metadata_pld_valid_reg <= 1'h0;
      __t__streaming_pld_reg <= __t__streaming_pld_reg_init;
      __t__streaming_pld_valid_reg <= 1'h0;
    end else begin
      p0_valid <= p0_enable ? p0_stage_done : p0_valid;
      p1_valid <= p1_enable ? p0_valid : p1_valid;
      __t__unified_pld_reg <= t__unified_pld_load_en ? t__unified_pld : __t__unified_pld_reg;
      __t__unified_pld_valid_reg <= t__unified_pld_valid_load_en ? t__unified_pld_vld : __t__unified_pld_valid_reg;
      __t__metadata_pld_reg <= t__metadata_pld_load_en ? __t__unified_pld_reg : __t__metadata_pld_reg;
      __t__metadata_pld_valid_reg <= t__metadata_pld_valid_load_en ? __t__metadata_pld_vld_buf : __t__metadata_pld_valid_reg;
      __t__streaming_pld_reg <= t__streaming_pld_load_en ? __t__unified_pld_reg : __t__streaming_pld_reg;
      __t__streaming_pld_valid_reg <= t__streaming_pld_valid_load_en ? __t__streaming_pld_vld_buf : __t__streaming_pld_valid_reg;
    end
  end
  assign t__metadata_pld = __t__metadata_pld_reg;
  assign t__metadata_pld_vld = __t__metadata_pld_valid_reg;
  assign t__streaming_pld = __t__streaming_pld_reg;
  assign t__streaming_pld_vld = __t__streaming_pld_valid_reg;
  assign t__unified_pld_rdy = t__unified_pld_load_en;
endmodule
