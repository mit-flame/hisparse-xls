module __t__pe_addr_arbiter_0_next(
  input wire clk,
  input wire rst,
  input wire [127:0] t__clearing_addr,
  input wire t__clearing_addr_vld,
  input wire [127:0] t__result_addr,
  input wire t__result_addr_vld,
  input wire [127:0] t__streaming_addr,
  input wire t__streaming_addr_vld,
  input wire t__unified_addr_rdy,
  output wire t__clearing_addr_rdy,
  output wire t__result_addr_rdy,
  output wire t__streaming_addr_rdy,
  output wire [127:0] t__unified_addr,
  output wire t__unified_addr_vld
);
  wire [127:0] __t__result_addr_reg_init = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] __t__streaming_addr_reg_init = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] __t__clearing_addr_reg_init = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] __t__unified_addr_reg_init = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] literal_170 = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] literal_174 = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] literal_180 = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  reg p0_valid;
  reg p1_valid;
  reg [127:0] __t__result_addr_reg;
  reg __t__result_addr_valid_reg;
  reg [127:0] __t__streaming_addr_reg;
  reg __t__streaming_addr_valid_reg;
  reg [127:0] __t__clearing_addr_reg;
  reg __t__clearing_addr_valid_reg;
  reg [127:0] __t__unified_addr_reg;
  reg __t__unified_addr_valid_reg;
  wire t__unified_addr_valid_inv;
  wire __t__unified_addr_vld_buf;
  wire t__unified_addr_valid_load_en;
  wire [127:0] t__result_addr_select;
  wire [127:0] t__streaming_addr_select;
  wire t__unified_addr_not_pred;
  wire t__unified_addr_load_en;
  wire [127:0] t__clearing_addr_select;
  wire p0_stage_done;
  wire t__clearing_addr_valid_inv;
  wire t__result_addr_valid_inv;
  wire t__streaming_addr_valid_inv;
  wire t__clearing_addr_valid_load_en;
  wire t__result_addr_valid_load_en;
  wire t__streaming_addr_valid_load_en;
  wire t__clearing_addr_load_en;
  wire t__result_addr_load_en;
  wire t__streaming_addr_load_en;
  wire p1_enable;
  wire p0_enable;
  wire [127:0] o_pld;
  assign t__unified_addr_valid_inv = ~__t__unified_addr_valid_reg;
  assign __t__unified_addr_vld_buf = __t__clearing_addr_valid_reg | __t__streaming_addr_valid_reg | __t__result_addr_valid_reg;
  assign t__unified_addr_valid_load_en = t__unified_addr_rdy | t__unified_addr_valid_inv;
  assign t__result_addr_select = __t__result_addr_valid_reg ? __t__result_addr_reg : literal_170;
  assign t__streaming_addr_select = __t__streaming_addr_valid_reg ? __t__streaming_addr_reg : literal_174;
  assign t__unified_addr_not_pred = ~__t__unified_addr_vld_buf;
  assign t__unified_addr_load_en = __t__unified_addr_vld_buf & t__unified_addr_valid_load_en;
  assign t__clearing_addr_select = __t__clearing_addr_valid_reg ? __t__clearing_addr_reg : literal_180;
  assign p0_stage_done = t__unified_addr_not_pred | t__unified_addr_load_en;
  assign t__clearing_addr_valid_inv = ~__t__clearing_addr_valid_reg;
  assign t__result_addr_valid_inv = ~__t__result_addr_valid_reg;
  assign t__streaming_addr_valid_inv = ~__t__streaming_addr_valid_reg;
  assign t__clearing_addr_valid_load_en = p0_stage_done | t__clearing_addr_valid_inv;
  assign t__result_addr_valid_load_en = p0_stage_done | t__result_addr_valid_inv;
  assign t__streaming_addr_valid_load_en = p0_stage_done | t__streaming_addr_valid_inv;
  assign t__clearing_addr_load_en = t__clearing_addr_vld & t__clearing_addr_valid_load_en;
  assign t__result_addr_load_en = t__result_addr_vld & t__result_addr_valid_load_en;
  assign t__streaming_addr_load_en = t__streaming_addr_vld & t__streaming_addr_valid_load_en;
  assign p1_enable = 1'h1;
  assign p0_enable = 1'h1;
  assign o_pld = {__t__clearing_addr_valid_reg ? t__clearing_addr_select[127:127] : (__t__streaming_addr_valid_reg ? t__streaming_addr_select[127:127] : t__result_addr_select[127:127]), __t__clearing_addr_valid_reg ? t__clearing_addr_select[126:125] : (__t__streaming_addr_valid_reg ? t__streaming_addr_select[126:125] : t__result_addr_select[126:125]), __t__clearing_addr_valid_reg ? t__clearing_addr_select[124:96] : (__t__streaming_addr_valid_reg ? t__streaming_addr_select[124:96] : t__result_addr_select[124:96]), __t__clearing_addr_valid_reg ? t__clearing_addr_select[95:64] : (__t__streaming_addr_valid_reg ? t__streaming_addr_select[95:64] : t__result_addr_select[95:64]), __t__clearing_addr_valid_reg ? t__clearing_addr_select[63:32] : (__t__streaming_addr_valid_reg ? t__streaming_addr_select[63:32] : t__result_addr_select[63:32]), __t__clearing_addr_valid_reg ? t__clearing_addr_select[31:0] : (__t__streaming_addr_valid_reg ? t__streaming_addr_select[31:0] : t__result_addr_select[31:0])};
  always_ff @ (posedge clk) begin
    if (rst) begin
      p0_valid <= 1'h0;
      p1_valid <= 1'h0;
      __t__result_addr_reg <= __t__result_addr_reg_init;
      __t__result_addr_valid_reg <= 1'h0;
      __t__streaming_addr_reg <= __t__streaming_addr_reg_init;
      __t__streaming_addr_valid_reg <= 1'h0;
      __t__clearing_addr_reg <= __t__clearing_addr_reg_init;
      __t__clearing_addr_valid_reg <= 1'h0;
      __t__unified_addr_reg <= __t__unified_addr_reg_init;
      __t__unified_addr_valid_reg <= 1'h0;
    end else begin
      p0_valid <= p0_enable ? p0_stage_done : p0_valid;
      p1_valid <= p1_enable ? p0_valid : p1_valid;
      __t__result_addr_reg <= t__result_addr_load_en ? t__result_addr : __t__result_addr_reg;
      __t__result_addr_valid_reg <= t__result_addr_valid_load_en ? t__result_addr_vld : __t__result_addr_valid_reg;
      __t__streaming_addr_reg <= t__streaming_addr_load_en ? t__streaming_addr : __t__streaming_addr_reg;
      __t__streaming_addr_valid_reg <= t__streaming_addr_valid_load_en ? t__streaming_addr_vld : __t__streaming_addr_valid_reg;
      __t__clearing_addr_reg <= t__clearing_addr_load_en ? t__clearing_addr : __t__clearing_addr_reg;
      __t__clearing_addr_valid_reg <= t__clearing_addr_valid_load_en ? t__clearing_addr_vld : __t__clearing_addr_valid_reg;
      __t__unified_addr_reg <= t__unified_addr_load_en ? o_pld : __t__unified_addr_reg;
      __t__unified_addr_valid_reg <= t__unified_addr_valid_load_en ? __t__unified_addr_vld_buf : __t__unified_addr_valid_reg;
    end
  end
  assign t__clearing_addr_rdy = t__clearing_addr_load_en;
  assign t__result_addr_rdy = t__result_addr_load_en;
  assign t__streaming_addr_rdy = t__streaming_addr_load_en;
  assign t__unified_addr = __t__unified_addr_reg;
  assign t__unified_addr_vld = __t__unified_addr_valid_reg;
endmodule
