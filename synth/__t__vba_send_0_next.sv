`default_nettype none
module __t__vba_send_0_next(
  input wire clk,
  input wire rst,
  input wire t__loading_addr_rdy,
  input wire [95:0] t__matrix_payload_two,
  input wire t__matrix_payload_two_vld,
  input wire [31:0] t__num_col_partitions,
  input wire t__num_col_partitions_vld,
  input wire t__streaming_addr_rdy,
  input wire [63:0] t__vector_payload_two,
  input wire t__vector_payload_two_vld,
  output wire [127:0] t__loading_addr,
  output wire t__loading_addr_vld,
  output wire t__matrix_payload_two_rdy,
  output wire t__num_col_partitions_rdy,
  output wire [127:0] t__streaming_addr,
  output wire t__streaming_addr_vld,
  output wire t__vector_payload_two_rdy
);
  wire [127:0] __t__loading_addr_reg_init = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] __t__streaming_addr_reg_init = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  reg [1:0] ____state_0;
  reg [31:0] ____state_2;
  reg [31:0] ____state_1;
  reg ____state_5;
  reg ____state_4;
  reg [63:0] __t__vector_payload_two_reg;
  reg __t__vector_payload_two_valid_reg;
  reg [95:0] __t__matrix_payload_two_reg;
  reg __t__matrix_payload_two_valid_reg;
  reg [31:0] __t__num_col_partitions_reg;
  reg __t__num_col_partitions_valid_reg;
  reg [127:0] __t__loading_addr_reg;
  reg __t__loading_addr_valid_reg;
  reg [127:0] __t__streaming_addr_reg;
  reg __t__streaming_addr_valid_reg;
  wire [1:0] unexpand_for_next_value_182_0_case_0;
  wire [1:0] unexpand_for_next_value_182_0_case_1_case_1;
  wire eq_897;
  wire eq_898;
  wire [63:0] t__vector_payload_two_select;
  wire [95:0] t__matrix_payload_two_select;
  wire nor_922;
  wire [1:0] cmd;
  wire [1:0] cmd__1;
  wire [1:0] unexpand_for_next_value_182_0_case_3_case_0;
  wire t__vector_payload_two_not_pred;
  wire t__matrix_payload_two_not_pred;
  wire t__num_col_partitions_not_pred;
  wire eq_939;
  wire [1:0] unexpand_for_next_value_182_0_case_2_case_1;
  wire [31:0] new_state;
  wire p0_all_active_inputs_valid;
  wire and_981;
  wire t__loading_addr_valid_inv;
  wire and_984;
  wire t__streaming_addr_valid_inv;
  wire eq_911;
  wire [31:0] new_cur_part__1;
  wire [31:0] add_913;
  wire __t__loading_addr_vld_buf;
  wire t__loading_addr_valid_load_en;
  wire __t__streaming_addr_vld_buf;
  wire t__streaming_addr_valid_load_en;
  wire new_state__1_1_case_cmp;
  wire new_state__2_1_case_cmp;
  wire new_state__3_1_case_cmp;
  wire t__loading_addr_not_pred;
  wire t__loading_addr_load_en;
  wire t__streaming_addr_not_pred;
  wire t__streaming_addr_load_en;
  wire nor_923;
  wire and_924;
  wire nor_925;
  wire and_926;
  wire nor_927;
  wire and_928;
  wire [1:0] ____state_2__next_value_predicates;
  wire [2:0] ____state_3__next_value_predicates;
  wire [2:0] ____state_4__next_value_predicates;
  wire [2:0] ____state_5__next_value_predicates;
  wire [6:0] ____state_0__next_value_predicates;
  wire p0_all_active_outputs_ready;
  wire [2:0] one_hot_943;
  wire [3:0] one_hot_944;
  wire [3:0] one_hot_945;
  wire [3:0] one_hot_946;
  wire [7:0] one_hot_947;
  wire p0_stage_done;
  wire t__matrix_payload_two_valid_inv;
  wire and_1088;
  wire t__num_col_partitions_valid_inv;
  wire t__vector_payload_two_valid_inv;
  wire and_1050;
  wire and_1051;
  wire t__matrix_payload_two_valid_load_en;
  wire t__num_col_partitions_valid_load_en;
  wire t__vector_payload_two_valid_load_en;
  wire ____state_2__at_most_one_next_value;
  wire ____state_3__at_most_one_next_value;
  wire ____state_4__at_most_one_next_value;
  wire ____state_5__at_most_one_next_value;
  wire ____state_0__at_most_one_next_value;
  wire [1:0] concat_1053;
  wire [31:0] new_cur_part;
  wire [2:0] concat_1061;
  wire new_vec_sod__1;
  wire new_vec_sod;
  wire [2:0] concat_1069;
  wire new_mtx_sod__1;
  wire [6:0] concat_1081;
  wire [31:0] data;
  wire [31:0] data__1;
  wire [31:0] row_indx;
  wire t__matrix_payload_two_load_en;
  wire t__num_col_partitions_load_en;
  wire t__vector_payload_two_load_en;
  wire or_1157;
  wire or_1159;
  wire or_1161;
  wire or_1163;
  wire or_1165;
  wire [31:0] t__num_col_partitions_select;
  wire [31:0] one_hot_sel_1054;
  wire and_1091;
  wire one_hot_sel_1062;
  wire and_1094;
  wire one_hot_sel_1070;
  wire and_1097;
  wire [1:0] one_hot_sel_1082;
  wire and_1100;
  wire [127:0] loading_pld;
  wire [127:0] streaming_pld;
  assign unexpand_for_next_value_182_0_case_0 = 2'h1;
  assign unexpand_for_next_value_182_0_case_1_case_1 = 2'h2;
  assign eq_897 = ____state_0 == unexpand_for_next_value_182_0_case_0;
  assign eq_898 = ____state_0 == unexpand_for_next_value_182_0_case_1_case_1;
  assign t__vector_payload_two_select = eq_897 ? __t__vector_payload_two_reg : 64'h0000_0000_0000_0000;
  assign t__matrix_payload_two_select = eq_898 ? __t__matrix_payload_two_reg : 96'h0000_0000_0000_0000_0000_0000;
  assign nor_922 = ~(____state_0[0] | ____state_0[1]);
  assign cmd = t__vector_payload_two_select[63:62];
  assign cmd__1 = t__matrix_payload_two_select[95:94];
  assign unexpand_for_next_value_182_0_case_3_case_0 = 2'h0;
  assign t__vector_payload_two_not_pred = ~eq_897;
  assign t__matrix_payload_two_not_pred = ~eq_898;
  assign t__num_col_partitions_not_pred = ~nor_922;
  assign eq_939 = cmd == unexpand_for_next_value_182_0_case_0;
  assign unexpand_for_next_value_182_0_case_2_case_1 = 2'h3;
  assign new_state = 32'h0000_0001;
  assign p0_all_active_inputs_valid = (t__vector_payload_two_not_pred | __t__vector_payload_two_valid_reg) & (t__matrix_payload_two_not_pred | __t__matrix_payload_two_valid_reg) & (t__num_col_partitions_not_pred | __t__num_col_partitions_valid_reg);
  assign and_981 = eq_897 & cmd != unexpand_for_next_value_182_0_case_1_case_1 & ~eq_939 & ____state_4;
  assign t__loading_addr_valid_inv = ~__t__loading_addr_valid_reg;
  assign and_984 = eq_898 & (cmd__1 != unexpand_for_next_value_182_0_case_3_case_0 | t__matrix_payload_two_select != 96'h0000_0000_0000_0000_0000_0000 & ____state_5);
  assign t__streaming_addr_valid_inv = ~__t__streaming_addr_valid_reg;
  assign eq_911 = ____state_0 == unexpand_for_next_value_182_0_case_2_case_1;
  assign new_cur_part__1 = ____state_2 + new_state;
  assign add_913 = ____state_1 + new_state;
  assign __t__loading_addr_vld_buf = p0_all_active_inputs_valid & and_981;
  assign t__loading_addr_valid_load_en = t__loading_addr_rdy | t__loading_addr_valid_inv;
  assign __t__streaming_addr_vld_buf = p0_all_active_inputs_valid & and_984;
  assign t__streaming_addr_valid_load_en = t__streaming_addr_rdy | t__streaming_addr_valid_inv;
  assign new_state__1_1_case_cmp = t__vector_payload_two_select[63];
  assign new_state__2_1_case_cmp = t__matrix_payload_two_select[95];
  assign new_state__3_1_case_cmp = new_cur_part__1 < add_913;
  assign t__loading_addr_not_pred = ~and_981;
  assign t__loading_addr_load_en = __t__loading_addr_vld_buf & t__loading_addr_valid_load_en;
  assign t__streaming_addr_not_pred = ~and_984;
  assign t__streaming_addr_load_en = __t__streaming_addr_vld_buf & t__streaming_addr_valid_load_en;
  assign nor_923 = ~(t__vector_payload_two_not_pred | new_state__1_1_case_cmp);
  assign and_924 = eq_897 & new_state__1_1_case_cmp;
  assign nor_925 = ~(t__matrix_payload_two_not_pred | new_state__2_1_case_cmp);
  assign and_926 = eq_898 & new_state__2_1_case_cmp;
  assign nor_927 = ~(~eq_911 | new_state__3_1_case_cmp);
  assign and_928 = eq_911 & new_state__3_1_case_cmp;
  assign ____state_2__next_value_predicates = {nor_922, eq_911};
  assign ____state_3__next_value_predicates = {nor_922, eq_897, eq_898};
  assign ____state_4__next_value_predicates = {nor_922, eq_897, eq_911};
  assign ____state_5__next_value_predicates = {nor_922, eq_898, eq_911};
  assign ____state_0__next_value_predicates = {nor_922, nor_923, and_924, nor_925, and_926, nor_927, and_928};
  assign p0_all_active_outputs_ready = (t__loading_addr_not_pred | t__loading_addr_load_en) & (t__streaming_addr_not_pred | t__streaming_addr_load_en);
  assign one_hot_943 = {____state_2__next_value_predicates[1:0] == 2'h0, ____state_2__next_value_predicates[1] && !____state_2__next_value_predicates[0], ____state_2__next_value_predicates[0]};
  assign one_hot_944 = {____state_3__next_value_predicates[2:0] == 3'h0, ____state_3__next_value_predicates[2] && ____state_3__next_value_predicates[1:0] == 2'h0, ____state_3__next_value_predicates[1] && !____state_3__next_value_predicates[0], ____state_3__next_value_predicates[0]};
  assign one_hot_945 = {____state_4__next_value_predicates[2:0] == 3'h0, ____state_4__next_value_predicates[2] && ____state_4__next_value_predicates[1:0] == 2'h0, ____state_4__next_value_predicates[1] && !____state_4__next_value_predicates[0], ____state_4__next_value_predicates[0]};
  assign one_hot_946 = {____state_5__next_value_predicates[2:0] == 3'h0, ____state_5__next_value_predicates[2] && ____state_5__next_value_predicates[1:0] == 2'h0, ____state_5__next_value_predicates[1] && !____state_5__next_value_predicates[0], ____state_5__next_value_predicates[0]};
  assign one_hot_947 = {____state_0__next_value_predicates[6:0] == 7'h00, ____state_0__next_value_predicates[6] && ____state_0__next_value_predicates[5:0] == 6'h00, ____state_0__next_value_predicates[5] && ____state_0__next_value_predicates[4:0] == 5'h00, ____state_0__next_value_predicates[4] && ____state_0__next_value_predicates[3:0] == 4'h0, ____state_0__next_value_predicates[3] && ____state_0__next_value_predicates[2:0] == 3'h0, ____state_0__next_value_predicates[2] && ____state_0__next_value_predicates[1:0] == 2'h0, ____state_0__next_value_predicates[1] && !____state_0__next_value_predicates[0], ____state_0__next_value_predicates[0]};
  assign p0_stage_done = p0_all_active_inputs_valid & p0_all_active_outputs_ready;
  assign t__matrix_payload_two_valid_inv = ~__t__matrix_payload_two_valid_reg;
  assign and_1088 = nor_922 & p0_stage_done;
  assign t__num_col_partitions_valid_inv = ~__t__num_col_partitions_valid_reg;
  assign t__vector_payload_two_valid_inv = ~__t__vector_payload_two_valid_reg;
  assign and_1050 = nor_922 & p0_stage_done;
  assign and_1051 = eq_911 & p0_stage_done;
  assign t__matrix_payload_two_valid_load_en = p0_stage_done & eq_898 | t__matrix_payload_two_valid_inv;
  assign t__num_col_partitions_valid_load_en = and_1088 | t__num_col_partitions_valid_inv;
  assign t__vector_payload_two_valid_load_en = p0_stage_done & eq_897 | t__vector_payload_two_valid_inv;
  assign ____state_2__at_most_one_next_value = nor_922 == one_hot_943[1] & eq_911 == one_hot_943[0];
  assign ____state_3__at_most_one_next_value = nor_922 == one_hot_944[2] & eq_897 == one_hot_944[1] & eq_898 == one_hot_944[0];
  assign ____state_4__at_most_one_next_value = nor_922 == one_hot_945[2] & eq_897 == one_hot_945[1] & eq_911 == one_hot_945[0];
  assign ____state_5__at_most_one_next_value = nor_922 == one_hot_946[2] & eq_898 == one_hot_946[1] & eq_911 == one_hot_946[0];
  assign ____state_0__at_most_one_next_value = nor_922 == one_hot_947[6] & nor_923 == one_hot_947[5] & and_924 == one_hot_947[4] & nor_925 == one_hot_947[3] & and_926 == one_hot_947[2] & nor_927 == one_hot_947[1] & and_928 == one_hot_947[0];
  assign concat_1053 = {and_1050, and_1051};
  assign new_cur_part = 32'h0000_0000;
  assign concat_1061 = {and_1050, eq_897 & p0_stage_done, and_1051};
  assign new_vec_sod__1 = eq_939 | ____state_4;
  assign new_vec_sod = 1'h0;
  assign concat_1069 = {and_1050, eq_898 & p0_stage_done, and_1051};
  assign new_mtx_sod__1 = cmd__1 == unexpand_for_next_value_182_0_case_0 | ____state_5;
  assign concat_1081 = {and_1050, nor_923 & p0_stage_done, and_924 & p0_stage_done, nor_925 & p0_stage_done, and_926 & p0_stage_done, nor_927 & p0_stage_done, and_928 & p0_stage_done};
  assign data = t__vector_payload_two_select[31:0];
  assign data__1 = t__matrix_payload_two_select[31:0];
  assign row_indx = t__matrix_payload_two_select[63:32];
  assign t__matrix_payload_two_load_en = t__matrix_payload_two_vld & t__matrix_payload_two_valid_load_en;
  assign t__num_col_partitions_load_en = t__num_col_partitions_vld & t__num_col_partitions_valid_load_en;
  assign t__vector_payload_two_load_en = t__vector_payload_two_vld & t__vector_payload_two_valid_load_en;
  assign or_1157 = ~p0_stage_done | ____state_2__at_most_one_next_value | rst;
  assign or_1159 = ~p0_stage_done | ____state_3__at_most_one_next_value | rst;
  assign or_1161 = ~p0_stage_done | ____state_4__at_most_one_next_value | rst;
  assign or_1163 = ~p0_stage_done | ____state_5__at_most_one_next_value | rst;
  assign or_1165 = ~p0_stage_done | ____state_0__at_most_one_next_value | rst;
  assign t__num_col_partitions_select = nor_922 ? __t__num_col_partitions_reg : 32'h0000_0000;
  assign one_hot_sel_1054 = new_cur_part__1 & {32{concat_1053[0]}} | new_cur_part & {32{concat_1053[1]}};
  assign and_1091 = (nor_922 | eq_911) & p0_stage_done;
  assign one_hot_sel_1062 = new_vec_sod & concat_1061[0] | new_vec_sod__1 & concat_1061[1] | new_vec_sod & concat_1061[2];
  assign and_1094 = (nor_922 | eq_897 | eq_911) & p0_stage_done;
  assign one_hot_sel_1070 = new_vec_sod & concat_1069[0] | new_mtx_sod__1 & concat_1069[1] | new_vec_sod & concat_1069[2];
  assign and_1097 = (nor_922 | eq_898 | eq_911) & p0_stage_done;
  assign one_hot_sel_1082 = unexpand_for_next_value_182_0_case_0 & {2{concat_1081[0]}} | unexpand_for_next_value_182_0_case_3_case_0 & {2{concat_1081[1]}} | unexpand_for_next_value_182_0_case_2_case_1 & {2{concat_1081[2]}} | unexpand_for_next_value_182_0_case_1_case_1 & {2{concat_1081[3]}} | unexpand_for_next_value_182_0_case_1_case_1 & {2{concat_1081[4]}} | unexpand_for_next_value_182_0_case_0 & {2{concat_1081[5]}} | unexpand_for_next_value_182_0_case_0 & {2{concat_1081[6]}};
  assign and_1100 = (nor_922 | nor_923 | and_924 | nor_925 | and_926 | nor_927 | and_928) & p0_stage_done;
  assign loading_pld = {1'h1, unexpand_for_next_value_182_0_case_3_case_0, {28'h000_0000, t__vector_payload_two_select[33]}, data, new_cur_part, new_cur_part};
  assign streaming_pld = {new_vec_sod, cmd__1, {28'h000_0000, t__matrix_payload_two_select[65]}, new_cur_part, data__1, row_indx};
  always_ff @ (posedge clk) begin
    if (rst) begin
      ____state_0 <= 2'h0;
      ____state_2 <= 32'h0000_0000;
      ____state_1 <= 32'h0000_0000;
      ____state_5 <= 1'h0;
      ____state_4 <= 1'h0;
      __t__vector_payload_two_reg <= 64'h0000_0000_0000_0000;
      __t__vector_payload_two_valid_reg <= 1'h0;
      __t__matrix_payload_two_reg <= 96'h0000_0000_0000_0000_0000_0000;
      __t__matrix_payload_two_valid_reg <= 1'h0;
      __t__num_col_partitions_reg <= 32'h0000_0000;
      __t__num_col_partitions_valid_reg <= 1'h0;
      __t__loading_addr_reg <= __t__loading_addr_reg_init;
      __t__loading_addr_valid_reg <= 1'h0;
      __t__streaming_addr_reg <= __t__streaming_addr_reg_init;
      __t__streaming_addr_valid_reg <= 1'h0;
    end else begin
      ____state_0 <= and_1100 ? one_hot_sel_1082 : ____state_0;
      ____state_2 <= and_1091 ? one_hot_sel_1054 : ____state_2;
      ____state_1 <= and_1088 ? t__num_col_partitions_select : ____state_1;
      ____state_5 <= and_1097 ? one_hot_sel_1070 : ____state_5;
      ____state_4 <= and_1094 ? one_hot_sel_1062 : ____state_4;
      __t__vector_payload_two_reg <= t__vector_payload_two_load_en ? t__vector_payload_two : __t__vector_payload_two_reg;
      __t__vector_payload_two_valid_reg <= t__vector_payload_two_valid_load_en ? t__vector_payload_two_vld : __t__vector_payload_two_valid_reg;
      __t__matrix_payload_two_reg <= t__matrix_payload_two_load_en ? t__matrix_payload_two : __t__matrix_payload_two_reg;
      __t__matrix_payload_two_valid_reg <= t__matrix_payload_two_valid_load_en ? t__matrix_payload_two_vld : __t__matrix_payload_two_valid_reg;
      __t__num_col_partitions_reg <= t__num_col_partitions_load_en ? t__num_col_partitions : __t__num_col_partitions_reg;
      __t__num_col_partitions_valid_reg <= t__num_col_partitions_valid_load_en ? t__num_col_partitions_vld : __t__num_col_partitions_valid_reg;
      __t__loading_addr_reg <= t__loading_addr_load_en ? loading_pld : __t__loading_addr_reg;
      __t__loading_addr_valid_reg <= t__loading_addr_valid_load_en ? __t__loading_addr_vld_buf : __t__loading_addr_valid_reg;
      __t__streaming_addr_reg <= t__streaming_addr_load_en ? streaming_pld : __t__streaming_addr_reg;
      __t__streaming_addr_valid_reg <= t__streaming_addr_valid_load_en ? __t__streaming_addr_vld_buf : __t__streaming_addr_valid_reg;
    end
  end
  assign t__loading_addr = __t__loading_addr_reg;
  assign t__loading_addr_vld = __t__loading_addr_valid_reg;
  assign t__matrix_payload_two_rdy = t__matrix_payload_two_load_en;
  assign t__num_col_partitions_rdy = t__num_col_partitions_load_en;
  assign t__streaming_addr = __t__streaming_addr_reg;
  assign t__streaming_addr_vld = __t__streaming_addr_valid_reg;
  assign t__vector_payload_two_rdy = t__vector_payload_two_load_en;
  `ifdef ASSERT_ON
  ____state_2__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_1157))) or_1157) else $fatal(0, "More than one next_value fired for state element: __state_2");
  ____state_3__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_1159))) or_1159) else $fatal(0, "More than one next_value fired for state element: __state_3");
  ____state_4__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_1161))) or_1161) else $fatal(0, "More than one next_value fired for state element: __state_4");
  ____state_5__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_1163))) or_1163) else $fatal(0, "More than one next_value fired for state element: __state_5");
  ____state_0__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_1165))) or_1165) else $fatal(0, "More than one next_value fired for state element: __state_0");
  `endif  // ASSERT_ON
endmodule
`default_nettype wire
