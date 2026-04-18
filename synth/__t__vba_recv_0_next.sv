`default_nettype none
module __t__vba_recv_0_next(
  input wire clk,
  input wire rst,
  input wire t__payload_type_three_rdy,
  input wire [95:0] t__streaming_pld,
  input wire t__streaming_pld_vld,
  output wire [95:0] t__payload_type_three,
  output wire t__payload_type_three_vld,
  output wire t__streaming_pld_rdy
);
  wire [95:0] __t__streaming_pld_reg_init = {2'h0, 30'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  reg [95:0] __t__streaming_pld_reg;
  reg __t__streaming_pld_valid_reg;
  reg [95:0] __t__payload_type_three_reg;
  reg __t__payload_type_three_valid_reg;
  wire t__payload_type_three_valid_inv;
  wire t__payload_type_three_valid_load_en;
  wire t__payload_type_three_load_en;
  wire p0_stage_done;
  wire t__streaming_pld_valid_inv;
  wire [1:0] spld_commands;
  wire [29:0] spld_row_index;
  wire [31:0] spld_vector;
  wire [31:0] spld_matrix_pld;
  wire t__streaming_pld_valid_load_en;
  wire t__streaming_pld_load_en;
  wire [95:0] opld;
  assign t__payload_type_three_valid_inv = ~__t__payload_type_three_valid_reg;
  assign t__payload_type_three_valid_load_en = t__payload_type_three_rdy | t__payload_type_three_valid_inv;
  assign t__payload_type_three_load_en = __t__streaming_pld_valid_reg & t__payload_type_three_valid_load_en;
  assign p0_stage_done = __t__streaming_pld_valid_reg & t__payload_type_three_load_en;
  assign t__streaming_pld_valid_inv = ~__t__streaming_pld_valid_reg;
  assign spld_commands = __t__streaming_pld_reg[95:94];
  assign spld_row_index = __t__streaming_pld_reg[93:64];
  assign spld_vector = __t__streaming_pld_reg[63:32];
  assign spld_matrix_pld = __t__streaming_pld_reg[31:0];
  assign t__streaming_pld_valid_load_en = p0_stage_done | t__streaming_pld_valid_inv;
  assign t__streaming_pld_load_en = t__streaming_pld_vld & t__streaming_pld_valid_load_en;
  assign opld = spld_commands != 2'h0 ? {spld_commands, 94'h0000_0000_0000_0000_0000_0000} : {2'h0, spld_row_index, spld_vector, spld_matrix_pld};
  always_ff @ (posedge clk) begin
    if (rst) begin
      __t__streaming_pld_reg <= __t__streaming_pld_reg_init;
      __t__streaming_pld_valid_reg <= 1'h0;
      __t__payload_type_three_reg <= 96'h0000_0000_0000_0000_0000_0000;
      __t__payload_type_three_valid_reg <= 1'h0;
    end else begin
      __t__streaming_pld_reg <= t__streaming_pld_load_en ? t__streaming_pld : __t__streaming_pld_reg;
      __t__streaming_pld_valid_reg <= t__streaming_pld_valid_load_en ? t__streaming_pld_vld : __t__streaming_pld_valid_reg;
      __t__payload_type_three_reg <= t__payload_type_three_load_en ? opld : __t__payload_type_three_reg;
      __t__payload_type_three_valid_reg <= t__payload_type_three_valid_load_en ? __t__streaming_pld_valid_reg : __t__payload_type_three_valid_reg;
    end
  end
  assign t__payload_type_three = __t__payload_type_three_reg;
  assign t__payload_type_three_vld = __t__payload_type_three_valid_reg;
  assign t__streaming_pld_rdy = t__streaming_pld_load_en;
endmodule
`default_nettype wire
