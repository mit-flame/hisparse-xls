`default_nettype none
module __t__vba_addr_arbiter_0_next(
  input wire clk,
  input wire rst,
  input wire [127:0] t__loading_addr,
  input wire t__loading_addr_vld,
  input wire [127:0] t__streaming_addr,
  input wire t__streaming_addr_vld,
  input wire t__unified_addr_rdy,
  output wire t__loading_addr_rdy,
  output wire t__streaming_addr_rdy,
  output wire [127:0] t__unified_addr,
  output wire t__unified_addr_vld
);
  wire [127:0] __t__streaming_addr_reg_init = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] __t__loading_addr_reg_init = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] __t__unified_addr_reg_init = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] literal_109 = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] literal_113 = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  reg [127:0] __t__streaming_addr_reg;
  reg __t__streaming_addr_valid_reg;
  reg [127:0] __t__loading_addr_reg;
  reg __t__loading_addr_valid_reg;
  reg [127:0] __t__unified_addr_reg;
  reg __t__unified_addr_valid_reg;
  wire t__unified_addr_valid_inv;
  wire __t__unified_addr_vld_buf;
  wire t__unified_addr_valid_load_en;
  wire t__unified_addr_not_pred;
  wire t__unified_addr_load_en;
  wire [127:0] t__streaming_addr_select;
  wire [127:0] t__loading_addr_select;
  wire p0_stage_done;
  wire t__loading_addr_valid_inv;
  wire t__streaming_addr_valid_inv;
  wire t__loading_addr_valid_load_en;
  wire t__streaming_addr_valid_load_en;
  wire t__loading_addr_load_en;
  wire t__streaming_addr_load_en;
  wire [127:0] o_pld;
  assign t__unified_addr_valid_inv = ~__t__unified_addr_valid_reg;
  assign __t__unified_addr_vld_buf = __t__loading_addr_valid_reg | __t__streaming_addr_valid_reg;
  assign t__unified_addr_valid_load_en = t__unified_addr_rdy | t__unified_addr_valid_inv;
  assign t__unified_addr_not_pred = ~__t__unified_addr_vld_buf;
  assign t__unified_addr_load_en = __t__unified_addr_vld_buf & t__unified_addr_valid_load_en;
  assign t__streaming_addr_select = __t__streaming_addr_valid_reg ? __t__streaming_addr_reg : literal_109;
  assign t__loading_addr_select = __t__loading_addr_valid_reg ? __t__loading_addr_reg : literal_113;
  assign p0_stage_done = t__unified_addr_not_pred | t__unified_addr_load_en;
  assign t__loading_addr_valid_inv = ~__t__loading_addr_valid_reg;
  assign t__streaming_addr_valid_inv = ~__t__streaming_addr_valid_reg;
  assign t__loading_addr_valid_load_en = p0_stage_done | t__loading_addr_valid_inv;
  assign t__streaming_addr_valid_load_en = p0_stage_done | t__streaming_addr_valid_inv;
  assign t__loading_addr_load_en = t__loading_addr_vld & t__loading_addr_valid_load_en;
  assign t__streaming_addr_load_en = t__streaming_addr_vld & t__streaming_addr_valid_load_en;
  assign o_pld = {__t__loading_addr_valid_reg ? t__loading_addr_select[127:127] : t__streaming_addr_select[127:127], __t__loading_addr_valid_reg ? t__loading_addr_select[126:125] : t__streaming_addr_select[126:125], __t__loading_addr_valid_reg ? t__loading_addr_select[124:96] : t__streaming_addr_select[124:96], __t__loading_addr_valid_reg ? t__loading_addr_select[95:64] : t__streaming_addr_select[95:64], __t__loading_addr_valid_reg ? t__loading_addr_select[63:32] : t__streaming_addr_select[63:32], __t__loading_addr_valid_reg ? t__loading_addr_select[31:0] : t__streaming_addr_select[31:0]};
  always_ff @ (posedge clk) begin
    if (rst) begin
      __t__streaming_addr_reg <= __t__streaming_addr_reg_init;
      __t__streaming_addr_valid_reg <= 1'h0;
      __t__loading_addr_reg <= __t__loading_addr_reg_init;
      __t__loading_addr_valid_reg <= 1'h0;
      __t__unified_addr_reg <= __t__unified_addr_reg_init;
      __t__unified_addr_valid_reg <= 1'h0;
    end else begin
      __t__streaming_addr_reg <= t__streaming_addr_load_en ? t__streaming_addr : __t__streaming_addr_reg;
      __t__streaming_addr_valid_reg <= t__streaming_addr_valid_load_en ? t__streaming_addr_vld : __t__streaming_addr_valid_reg;
      __t__loading_addr_reg <= t__loading_addr_load_en ? t__loading_addr : __t__loading_addr_reg;
      __t__loading_addr_valid_reg <= t__loading_addr_valid_load_en ? t__loading_addr_vld : __t__loading_addr_valid_reg;
      __t__unified_addr_reg <= t__unified_addr_load_en ? o_pld : __t__unified_addr_reg;
      __t__unified_addr_valid_reg <= t__unified_addr_valid_load_en ? __t__unified_addr_vld_buf : __t__unified_addr_valid_reg;
    end
  end
  assign t__loading_addr_rdy = t__loading_addr_load_en;
  assign t__streaming_addr_rdy = t__streaming_addr_load_en;
  assign t__unified_addr = __t__unified_addr_reg;
  assign t__unified_addr_vld = __t__unified_addr_valid_reg;
endmodule
`default_nettype wire
