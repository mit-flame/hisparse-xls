`default_nettype none
module __t__arbiter_wrapper_0_next(
  input wire clk,
  input wire rst,
  input wire t__combined_out_rdy,
  input wire [1:0] t__i_valid,
  input wire t__i_valid_vld,
  input wire [191:0] t__payload,
  input wire t__payload_vld,
  input wire [31:0] t__rotate_offset,
  input wire t__rotate_offset_vld,
  output wire [261:0] t__combined_out,
  output wire t__combined_out_vld,
  output wire t__i_valid_rdy,
  output wire t__payload_rdy,
  output wire t__rotate_offset_rdy
);
  wire __t__i_valid_reg_init[2];
  assign __t__i_valid_reg_init = '{1'h0, 1'h0};
  wire __t__i_valid_skid_reg_init[2];
  assign __t__i_valid_skid_reg_init = '{1'h0, 1'h0};
  wire [95:0] __t__payload_reg_init[2];
  assign __t__payload_reg_init = '{96'h0000_0000_0000_0000_0000_0000, 96'h0000_0000_0000_0000_0000_0000};
  wire [95:0] __t__payload_skid_reg_init[2];
  assign __t__payload_skid_reg_init = '{96'h0000_0000_0000_0000_0000_0000, 96'h0000_0000_0000_0000_0000_0000};
  wire [261:0] __t__combined_out_reg_init = {{96'h0000_0000_0000_0000_0000_0000, 96'h0000_0000_0000_0000_0000_0000}, {1'h0, 1'h0}, {32'h0000_0000, 32'h0000_0000}, {1'h0, 1'h0}, {1'h0, 1'h0}};
  wire literal_975[2];
  assign literal_975 = '{1'h0, 1'h0};
  wire literal_976[2];
  assign literal_976 = '{1'h1, 1'h1};
  wire t__i_valid_unflattened[2];
  assign t__i_valid_unflattened[0] = t__i_valid[0:0];
  assign t__i_valid_unflattened[1] = t__i_valid[1:1];
  wire [95:0] t__payload_unflattened[2];
  assign t__payload_unflattened[0] = t__payload[95:0];
  assign t__payload_unflattened[1] = t__payload[191:96];
  reg p0_valid;
  reg p1_valid;
  reg p2_valid;
  reg p3_valid;
  reg __t__i_valid_reg[2];
  reg __t__i_valid_skid_reg[2];
  reg __t__i_valid_valid_reg;
  reg __t__i_valid_valid_skid_reg;
  reg [31:0] __t__rotate_offset_reg;
  reg [31:0] __t__rotate_offset_skid_reg;
  reg __t__rotate_offset_valid_reg;
  reg __t__rotate_offset_valid_skid_reg;
  reg [95:0] __t__payload_reg[2];
  reg [95:0] __t__payload_skid_reg[2];
  reg __t__payload_valid_reg;
  reg __t__payload_valid_skid_reg;
  reg [261:0] __t__combined_out_reg;
  reg __t__combined_out_valid_reg;
  wire t__i_valid_select[2];
  wire array_index_1000;
  wire array_index_1001;
  wire [31:0] NUM_STREAMS;
  wire [31:0] t__rotate_offset_select;
  wire [1:0] i_v;
  wire [31:0] sub_1006;
  wire [95:0] t__payload_select[2];
  wire [1:0] or_1012;
  wire new_rotated_ild_found;
  wire new_rotated_ild_port__2;
  wire new_rotated_ild_port__1;
  wire [95:0] array_index_1029;
  wire new_rotated_ild_found__1;
  wire xor_1031;
  wire new_rotated_ild_found__3;
  wire and_1036;
  wire and_1037;
  wire ne_1038;
  wire ne_1039;
  wire t__i_valid_valid_or;
  wire t__rotate_offset_valid_or;
  wire t__payload_valid_or;
  wire t__combined_out_valid_inv;
  wire cmd_payload_predicate;
  wire p0_all_active_inputs_valid;
  wire t__combined_out_valid_load_en;
  wire t__combined_out_load_en;
  wire t__i_valid_from_skid_rdy;
  wire p0_stage_done;
  wire t__rotate_offset_from_skid_rdy;
  wire t__payload_from_skid_rdy;
  wire t__i_valid_data_valid_load_en;
  wire t__i_valid_to_is_not_rdy;
  wire t__rotate_offset_data_valid_load_en;
  wire t__payload_data_valid_load_en;
  wire resend_valid[2];
  wire xbar_valid[2];
  wire t__i_valid_data_is_sent_to;
  wire t__i_valid_skid_data_load_en;
  wire t__i_valid_skid_valid_set_zero;
  wire t__rotate_offset_data_is_sent_to;
  wire t__rotate_offset_skid_data_load_en;
  wire t__rotate_offset_skid_valid_set_zero;
  wire t__payload_data_is_sent_to;
  wire t__payload_skid_data_load_en;
  wire t__payload_skid_valid_set_zero;
  wire rpv__1[2];
  wire [31:0] xs__1[2];
  wire xv__1[2];
  wire iv__1[2];
  wire p3_enable;
  wire p2_enable;
  wire p1_enable;
  wire p0_enable;
  wire t__i_valid_data_valid_load_en__1;
  wire t__i_valid_skid_valid_load_en;
  wire t__rotate_offset_data_valid_load_en__1;
  wire t__rotate_offset_skid_valid_load_en;
  wire t__payload_data_valid_load_en__1;
  wire t__payload_skid_valid_load_en;
  wire [261:0] __t__combined_out_buf;
  assign t__i_valid_select = __t__i_valid_valid_skid_reg == 1'h0 ? __t__i_valid_reg : __t__i_valid_skid_reg;
  assign array_index_1000 = t__i_valid_select[1'h0];
  assign array_index_1001 = t__i_valid_select[1'h1];
  assign NUM_STREAMS = 32'h0000_0002;
  assign t__rotate_offset_select = __t__rotate_offset_valid_skid_reg ? __t__rotate_offset_skid_reg : __t__rotate_offset_reg;
  assign i_v = {array_index_1000, array_index_1001};
  assign sub_1006 = NUM_STREAMS - t__rotate_offset_select;
  assign t__payload_select = __t__payload_valid_skid_reg == 1'h0 ? __t__payload_reg : __t__payload_skid_reg;
  assign or_1012 = (t__rotate_offset_select >= 32'h0000_0002 ? 2'h0 : i_v << t__rotate_offset_select) | (sub_1006 >= 32'h0000_0002 ? 2'h0 : i_v >> sub_1006);
  assign new_rotated_ild_found = ~(~or_1012[0] | t__payload_select[~t__rotate_offset_select[0]][64]);
  assign new_rotated_ild_port__2 = ~(or_1012[1] & ~t__payload_select[t__rotate_offset_select[0]][64]) & new_rotated_ild_found;
  assign new_rotated_ild_port__1 = ~(or_1012[1] & t__payload_select[t__rotate_offset_select[0]][64]) & or_1012[0] & t__payload_select[~t__rotate_offset_select[0]][64];
  assign array_index_1029 = t__payload_select[1'h0];
  assign new_rotated_ild_found__1 = ~(~or_1012[1] | t__payload_select[t__rotate_offset_select[0]][64]) | new_rotated_ild_port__2;
  assign xor_1031 = new_rotated_ild_port__2 ^ t__rotate_offset_select[0];
  assign new_rotated_ild_found__3 = or_1012[1] & t__payload_select[t__rotate_offset_select[0]][64] | new_rotated_ild_port__1;
  assign and_1036 = new_rotated_ild_found__1 & xor_1031;
  assign and_1037 = new_rotated_ild_found__3 & (new_rotated_ild_port__1 ^ t__rotate_offset_select[0]);
  assign ne_1038 = array_index_1029[95:94] != 2'h0;
  assign ne_1039 = array_index_1029[95:94] != 2'h2;
  assign t__i_valid_valid_or = __t__i_valid_valid_reg | __t__i_valid_valid_skid_reg;
  assign t__rotate_offset_valid_or = __t__rotate_offset_valid_reg | __t__rotate_offset_valid_skid_reg;
  assign t__payload_valid_or = __t__payload_valid_reg | __t__payload_valid_skid_reg;
  assign t__combined_out_valid_inv = ~__t__combined_out_valid_reg;
  assign cmd_payload_predicate = ne_1038 & ne_1039;
  assign p0_all_active_inputs_valid = t__i_valid_valid_or & t__rotate_offset_valid_or & t__payload_valid_or;
  assign t__combined_out_valid_load_en = t__combined_out_rdy | t__combined_out_valid_inv;
  assign t__combined_out_load_en = p0_all_active_inputs_valid & t__combined_out_valid_load_en;
  assign t__i_valid_from_skid_rdy = ~__t__i_valid_valid_skid_reg;
  assign p0_stage_done = p0_all_active_inputs_valid & t__combined_out_load_en;
  assign t__rotate_offset_from_skid_rdy = ~__t__rotate_offset_valid_skid_reg;
  assign t__payload_from_skid_rdy = ~__t__payload_valid_skid_reg;
  assign t__i_valid_data_valid_load_en = t__i_valid_vld & t__i_valid_from_skid_rdy;
  assign t__i_valid_to_is_not_rdy = ~p0_stage_done;
  assign t__rotate_offset_data_valid_load_en = t__rotate_offset_vld & t__rotate_offset_from_skid_rdy;
  assign t__payload_data_valid_load_en = t__payload_vld & t__payload_from_skid_rdy;
  assign resend_valid[0] = ~(array_index_1000 & ~(array_index_1029[64] ? and_1037 : and_1036) & (array_index_1029[64] ? new_rotated_ild_found__3 : new_rotated_ild_found__1)) & array_index_1000;
  assign resend_valid[1] = ~(~array_index_1001 | (t__payload_select[1'h1][64] ? and_1037 : and_1036));
  assign xbar_valid[0] = new_rotated_ild_found__1;
  assign xbar_valid[1] = new_rotated_ild_found__3;
  assign t__i_valid_data_is_sent_to = __t__i_valid_valid_reg & p0_stage_done & t__i_valid_from_skid_rdy;
  assign t__i_valid_skid_data_load_en = __t__i_valid_valid_reg & t__i_valid_data_valid_load_en & t__i_valid_to_is_not_rdy;
  assign t__i_valid_skid_valid_set_zero = __t__i_valid_valid_skid_reg & p0_stage_done;
  assign t__rotate_offset_data_is_sent_to = __t__rotate_offset_valid_reg & p0_stage_done & t__rotate_offset_from_skid_rdy;
  assign t__rotate_offset_skid_data_load_en = __t__rotate_offset_valid_reg & t__rotate_offset_data_valid_load_en & t__i_valid_to_is_not_rdy;
  assign t__rotate_offset_skid_valid_set_zero = __t__rotate_offset_valid_skid_reg & p0_stage_done;
  assign t__payload_data_is_sent_to = __t__payload_valid_reg & p0_stage_done & t__payload_from_skid_rdy;
  assign t__payload_skid_data_load_en = __t__payload_valid_reg & t__payload_data_valid_load_en & t__i_valid_to_is_not_rdy;
  assign t__payload_skid_valid_set_zero = __t__payload_valid_skid_reg & p0_stage_done;
  assign rpv__1 = cmd_payload_predicate == 1'h0 ? resend_valid : literal_975;
  assign xs__1[0] = {31'h0000_0000, ~(cmd_payload_predicate | ~new_rotated_ild_found__1) & xor_1031};
  assign xs__1[1] = {31'h0000_0000, cmd_payload_predicate | ~(ne_1038 & ne_1039) & and_1037};
  assign xv__1 = cmd_payload_predicate == 1'h0 ? xbar_valid : literal_976;
  assign iv__1 = cmd_payload_predicate == 1'h0 ? t__i_valid_select : literal_976;
  assign p3_enable = 1'h1;
  assign p2_enable = 1'h1;
  assign p1_enable = 1'h1;
  assign p0_enable = 1'h1;
  assign t__i_valid_data_valid_load_en__1 = t__i_valid_data_is_sent_to | t__i_valid_data_valid_load_en;
  assign t__i_valid_skid_valid_load_en = t__i_valid_skid_data_load_en | t__i_valid_skid_valid_set_zero;
  assign t__rotate_offset_data_valid_load_en__1 = t__rotate_offset_data_is_sent_to | t__rotate_offset_data_valid_load_en;
  assign t__rotate_offset_skid_valid_load_en = t__rotate_offset_skid_data_load_en | t__rotate_offset_skid_valid_set_zero;
  assign t__payload_data_valid_load_en__1 = t__payload_data_is_sent_to | t__payload_data_valid_load_en;
  assign t__payload_skid_valid_load_en = t__payload_skid_data_load_en | t__payload_skid_valid_set_zero;
  assign __t__combined_out_buf = {{t__payload_select[1], t__payload_select[0]}, {rpv__1[1], rpv__1[0]}, {xs__1[1], xs__1[0]}, {xv__1[1], xv__1[0]}, {iv__1[1], iv__1[0]}};
  always_ff @ (posedge clk) begin
    if (rst) begin
      p0_valid <= 1'h0;
      p1_valid <= 1'h0;
      p2_valid <= 1'h0;
      p3_valid <= 1'h0;
      __t__i_valid_reg <= __t__i_valid_reg_init;
      __t__i_valid_skid_reg <= __t__i_valid_skid_reg_init;
      __t__i_valid_valid_reg <= 1'h0;
      __t__i_valid_valid_skid_reg <= 1'h0;
      __t__rotate_offset_reg <= 32'h0000_0000;
      __t__rotate_offset_skid_reg <= 32'h0000_0000;
      __t__rotate_offset_valid_reg <= 1'h0;
      __t__rotate_offset_valid_skid_reg <= 1'h0;
      __t__payload_reg <= __t__payload_reg_init;
      __t__payload_skid_reg <= __t__payload_skid_reg_init;
      __t__payload_valid_reg <= 1'h0;
      __t__payload_valid_skid_reg <= 1'h0;
      __t__combined_out_reg <= __t__combined_out_reg_init;
      __t__combined_out_valid_reg <= 1'h0;
    end else begin
      p0_valid <= p0_enable ? p0_stage_done : p0_valid;
      p1_valid <= p1_enable ? p0_valid : p1_valid;
      p2_valid <= p2_enable ? p1_valid : p2_valid;
      p3_valid <= p3_enable ? p2_valid : p3_valid;
      __t__i_valid_reg <= t__i_valid_data_valid_load_en ? t__i_valid_unflattened : __t__i_valid_reg;
      __t__i_valid_skid_reg <= t__i_valid_skid_data_load_en ? __t__i_valid_reg : __t__i_valid_skid_reg;
      __t__i_valid_valid_reg <= t__i_valid_data_valid_load_en__1 ? t__i_valid_vld : __t__i_valid_valid_reg;
      __t__i_valid_valid_skid_reg <= t__i_valid_skid_valid_load_en ? t__i_valid_from_skid_rdy : __t__i_valid_valid_skid_reg;
      __t__rotate_offset_reg <= t__rotate_offset_data_valid_load_en ? t__rotate_offset : __t__rotate_offset_reg;
      __t__rotate_offset_skid_reg <= t__rotate_offset_skid_data_load_en ? __t__rotate_offset_reg : __t__rotate_offset_skid_reg;
      __t__rotate_offset_valid_reg <= t__rotate_offset_data_valid_load_en__1 ? t__rotate_offset_vld : __t__rotate_offset_valid_reg;
      __t__rotate_offset_valid_skid_reg <= t__rotate_offset_skid_valid_load_en ? t__rotate_offset_from_skid_rdy : __t__rotate_offset_valid_skid_reg;
      __t__payload_reg <= t__payload_data_valid_load_en ? t__payload_unflattened : __t__payload_reg;
      __t__payload_skid_reg <= t__payload_skid_data_load_en ? __t__payload_reg : __t__payload_skid_reg;
      __t__payload_valid_reg <= t__payload_data_valid_load_en__1 ? t__payload_vld : __t__payload_valid_reg;
      __t__payload_valid_skid_reg <= t__payload_skid_valid_load_en ? t__payload_from_skid_rdy : __t__payload_valid_skid_reg;
      __t__combined_out_reg <= t__combined_out_load_en ? __t__combined_out_buf : __t__combined_out_reg;
      __t__combined_out_valid_reg <= t__combined_out_valid_load_en ? p0_all_active_inputs_valid : __t__combined_out_valid_reg;
    end
  end
  assign t__combined_out = __t__combined_out_reg;
  assign t__combined_out_vld = __t__combined_out_valid_reg;
  assign t__i_valid_rdy = t__i_valid_from_skid_rdy;
  assign t__payload_rdy = t__payload_from_skid_rdy;
  assign t__rotate_offset_rdy = t__rotate_offset_from_skid_rdy;
endmodule
`default_nettype wire
