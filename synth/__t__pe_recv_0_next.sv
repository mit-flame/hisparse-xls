`default_nettype none
module __t__pe_recv_0_next(
  input wire clk,
  input wire rst,
  input wire t__accumulation_addr_rdy,
  input wire t__payload_type_four_rdy,
  input wire [31:0] t__stream_id,
  input wire t__stream_id_vld,
  input wire [127:0] t__unified_pld,
  input wire t__unified_pld_vld,
  output wire [127:0] t__accumulation_addr,
  output wire t__accumulation_addr_vld,
  output wire [63:0] t__payload_type_four,
  output wire t__payload_type_four_vld,
  output wire t__stream_id_rdy,
  output wire t__unified_pld_rdy
);
  // lint_off SIGNED_TYPE
  // lint_off MULTIPLY
  function automatic [15:0] smul16b_16b_x_16b (input reg [15:0] lhs, input reg [15:0] rhs);
    reg signed [15:0] signed_lhs;
    reg signed [15:0] signed_rhs;
    reg signed [15:0] signed_result;
    begin
      signed_lhs = $signed(lhs);
      signed_rhs = $signed(rhs);
      signed_result = signed_lhs * signed_rhs;
      smul16b_16b_x_16b = $unsigned(signed_result);
    end
  endfunction
  // lint_on MULTIPLY
  // lint_on SIGNED_TYPE
  wire [63:0] ____state_2_init[3];
  assign ____state_2_init = '{64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000};
  wire [127:0] __t__unified_pld_reg_init = {2'h0, 30'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] __t__accumulation_addr_reg_init = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] literal_671 = {2'h0, 30'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [63:0] new_queue[3];
  assign new_queue = '{64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000};
  reg ____state_0;
  reg [63:0] ____state_2[3];
  reg ____state_4;
  reg [31:0] ____state_1;
  reg [127:0] __t__unified_pld_reg;
  reg __t__unified_pld_valid_reg;
  reg [31:0] __t__stream_id_reg;
  reg __t__stream_id_valid_reg;
  reg [127:0] __t__accumulation_addr_reg;
  reg __t__accumulation_addr_valid_reg;
  reg [63:0] __t__payload_type_four_reg;
  reg __t__payload_type_four_valid_reg;
  wire [127:0] t__unified_pld_select;
  wire [1:0] spld_commands__2;
  wire [63:0] array_index_674;
  wire accumulate;
  wire [63:0] element__2;
  wire [29:0] spld_addr;
  wire p0_all_active_inputs_valid;
  wire and_727;
  wire t__accumulation_addr_valid_inv;
  wire and_743;
  wire t__payload_type_four_valid_inv;
  wire [63:0] element__1;
  wire __t__accumulation_addr_vld_buf;
  wire t__accumulation_addr_valid_load_en;
  wire __t__payload_type_four_vld_buf;
  wire t__payload_type_four_valid_load_en;
  wire new_state__1_1_case_cmp;
  wire match_pred;
  wire [31:0] spld_mem_base;
  wire [31:0] spld_matrix_val;
  wire [31:0] spld_vector_val;
  wire t__accumulation_addr_not_pred;
  wire t__accumulation_addr_load_en;
  wire t__payload_type_four_not_pred;
  wire t__payload_type_four_load_en;
  wire nor_708;
  wire and_709;
  wire match_pred__1;
  wire [31:0] n_base;
  wire [1:0] ____state_2__next_value_predicates;
  wire [2:0] ____state_0__next_value_predicates;
  wire match_pred__2;
  wire [31:0] n_base__1;
  wire [15:0] smul_707;
  wire p0_all_active_outputs_ready;
  wire [2:0] one_hot_722;
  wire [3:0] one_hot_723;
  wire [31:0] base;
  wire [31:0] incr;
  wire p0_stage_done;
  wire new_seen_sod;
  wire [31:0] add_719;
  wire and_804;
  wire t__stream_id_valid_inv;
  wire t__unified_pld_valid_inv;
  wire and_782;
  wire [63:0] update;
  wire t__stream_id_valid_load_en;
  wire t__unified_pld_valid_load_en;
  wire ____state_2__at_most_one_next_value;
  wire ____state_0__at_most_one_next_value;
  wire [1:0] concat_784;
  wire [63:0] new_queue__1[3];
  wire new_seen_sod__1;
  wire [2:0] concat_797;
  wire unexpand_for_next_value_159_0_case_0;
  wire [28:0] add_728;
  wire t__stream_id_load_en;
  wire t__unified_pld_load_en;
  wire or_860;
  wire or_866;
  wire [31:0] t__stream_id_select;
  wire [63:0] one_hot_sel_785[3];
  wire one_hot_sel_791;
  wire one_hot_sel_798;
  wire and_813;
  wire [127:0] update_pld;
  wire [63:0] stream_pld;
  assign t__unified_pld_select = ____state_0 ? __t__unified_pld_reg : literal_671;
  assign spld_commands__2 = t__unified_pld_select[127:126];
  assign array_index_674 = ____state_2[2'h2];
  assign accumulate = ~(spld_commands__2[0] | spld_commands__2[1] | ____state_4);
  assign element__2 = ____state_2[2'h1];
  assign spld_addr = t__unified_pld_select[125:96];
  assign p0_all_active_inputs_valid = (~____state_0 | __t__unified_pld_valid_reg) & (____state_0 | __t__stream_id_valid_reg);
  assign and_727 = ____state_0 & accumulate;
  assign t__accumulation_addr_valid_inv = ~__t__accumulation_addr_valid_reg;
  assign and_743 = ____state_0 & (spld_commands__2[0] | spld_commands__2[1] | ____state_4);
  assign t__payload_type_four_valid_inv = ~__t__payload_type_four_valid_reg;
  assign element__1 = ____state_2[2'h0];
  assign __t__accumulation_addr_vld_buf = p0_all_active_inputs_valid & and_727;
  assign t__accumulation_addr_valid_load_en = t__accumulation_addr_rdy | t__accumulation_addr_valid_inv;
  assign __t__payload_type_four_vld_buf = p0_all_active_inputs_valid & and_743;
  assign t__payload_type_four_valid_load_en = t__payload_type_four_rdy | t__payload_type_four_valid_inv;
  assign new_state__1_1_case_cmp = spld_commands__2 == 2'h3;
  assign match_pred = array_index_674[63:62] == 2'h1 & array_index_674[61:32] == spld_addr;
  assign spld_mem_base = t__unified_pld_select[31:0];
  assign spld_matrix_val = t__unified_pld_select[95:64];
  assign spld_vector_val = t__unified_pld_select[63:32];
  assign t__accumulation_addr_not_pred = ~and_727;
  assign t__accumulation_addr_load_en = __t__accumulation_addr_vld_buf & t__accumulation_addr_valid_load_en;
  assign t__payload_type_four_not_pred = ~and_743;
  assign t__payload_type_four_load_en = __t__payload_type_four_vld_buf & t__payload_type_four_valid_load_en;
  assign nor_708 = ~(~____state_0 | new_state__1_1_case_cmp);
  assign and_709 = ____state_0 & new_state__1_1_case_cmp;
  assign match_pred__1 = element__2[63:62] == 2'h1 & element__2[61:32] == spld_addr;
  assign n_base = match_pred ? array_index_674[31:0] : spld_mem_base;
  assign ____state_2__next_value_predicates = {~____state_0, ____state_0};
  assign ____state_0__next_value_predicates = {~____state_0, nor_708, and_709};
  assign match_pred__2 = element__1[63:62] == 2'h1 & element__1[61:32] == spld_addr;
  assign n_base__1 = match_pred__1 ? element__2[31:0] : n_base;
  assign smul_707 = smul16b_16b_x_16b(spld_matrix_val[15:0], spld_vector_val[15:0]);
  assign p0_all_active_outputs_ready = (t__accumulation_addr_not_pred | t__accumulation_addr_load_en) & (t__payload_type_four_not_pred | t__payload_type_four_load_en);
  assign one_hot_722 = {____state_2__next_value_predicates[1:0] == 2'h0, ____state_2__next_value_predicates[1] && !____state_2__next_value_predicates[0], ____state_2__next_value_predicates[0]};
  assign one_hot_723 = {____state_0__next_value_predicates[2:0] == 3'h0, ____state_0__next_value_predicates[2] && ____state_0__next_value_predicates[1:0] == 2'h0, ____state_0__next_value_predicates[1] && !____state_0__next_value_predicates[0], ____state_0__next_value_predicates[0]};
  assign base = match_pred__2 ? element__1[31:0] : n_base__1;
  assign incr = {{16{smul_707[15]}}, smul_707};
  assign p0_stage_done = p0_all_active_inputs_valid & p0_all_active_outputs_ready;
  assign new_seen_sod = 1'h0;
  assign add_719 = base + incr;
  assign and_804 = ~____state_0 & p0_stage_done;
  assign t__stream_id_valid_inv = ~__t__stream_id_valid_reg;
  assign t__unified_pld_valid_inv = ~__t__unified_pld_valid_reg;
  assign and_782 = ~____state_0 & p0_stage_done;
  assign update = {new_seen_sod, spld_matrix_val != 32'h0000_0000, spld_addr, add_719};
  assign t__stream_id_valid_load_en = and_804 | t__stream_id_valid_inv;
  assign t__unified_pld_valid_load_en = p0_stage_done & ____state_0 | t__unified_pld_valid_inv;
  assign ____state_2__at_most_one_next_value = ~____state_0 == one_hot_722[1] & ____state_0 == one_hot_722[0];
  assign ____state_0__at_most_one_next_value = ~____state_0 == one_hot_723[2] & nor_708 == one_hot_723[1] & and_709 == one_hot_723[0];
  assign concat_784 = {and_782, ____state_0 & p0_stage_done};
  assign new_queue__1[0] = update;
  assign new_queue__1[1] = element__1;
  assign new_queue__1[2] = element__2;
  assign new_seen_sod__1 = spld_commands__2 == 2'h1 | ____state_4;
  assign concat_797 = {and_782, nor_708 & p0_stage_done, and_709 & p0_stage_done};
  assign unexpand_for_next_value_159_0_case_0 = 1'h1;
  assign add_728 = spld_addr[28:0] + ____state_1[29:1];
  assign t__stream_id_load_en = t__stream_id_vld & t__stream_id_valid_load_en;
  assign t__unified_pld_load_en = t__unified_pld_vld & t__unified_pld_valid_load_en;
  assign or_860 = ~p0_stage_done | ____state_2__at_most_one_next_value | rst;
  assign or_866 = ~p0_stage_done | ____state_0__at_most_one_next_value | rst;
  assign t__stream_id_select = ~____state_0 ? __t__stream_id_reg : 32'h0000_0000;
  assign one_hot_sel_785[0] = new_queue__1[0] & {64{concat_784[0]}} | new_queue[0] & {64{concat_784[1]}};
  assign one_hot_sel_785[1] = new_queue__1[1] & {64{concat_784[0]}} | new_queue[1] & {64{concat_784[1]}};
  assign one_hot_sel_785[2] = new_queue__1[2] & {64{concat_784[0]}} | new_queue[2] & {64{concat_784[1]}};
  assign one_hot_sel_791 = new_seen_sod__1 & concat_784[0] | new_seen_sod & concat_784[1];
  assign one_hot_sel_798 = new_seen_sod & concat_797[0] | unexpand_for_next_value_159_0_case_0 & concat_797[1] | unexpand_for_next_value_159_0_case_0 & concat_797[2];
  assign and_813 = (~____state_0 | nor_708 | and_709) & p0_stage_done;
  assign update_pld = {unexpand_for_next_value_159_0_case_0, 2'h0, spld_addr[28:0], add_719, 32'h0000_0000, 32'h0000_0000};
  assign stream_pld = {spld_commands__2, add_728, ____state_1[0], spld_mem_base};
  always_ff @ (posedge clk) begin
    if (rst) begin
      ____state_0 <= 1'h0;
      ____state_2 <= ____state_2_init;
      ____state_4 <= 1'h0;
      ____state_1 <= 32'h0000_0000;
      __t__unified_pld_reg <= __t__unified_pld_reg_init;
      __t__unified_pld_valid_reg <= 1'h0;
      __t__stream_id_reg <= 32'h0000_0000;
      __t__stream_id_valid_reg <= 1'h0;
      __t__accumulation_addr_reg <= __t__accumulation_addr_reg_init;
      __t__accumulation_addr_valid_reg <= 1'h0;
      __t__payload_type_four_reg <= 64'h0000_0000_0000_0000;
      __t__payload_type_four_valid_reg <= 1'h0;
    end else begin
      ____state_0 <= and_813 ? one_hot_sel_798 : ____state_0;
      ____state_2 <= p0_stage_done ? one_hot_sel_785 : ____state_2;
      ____state_4 <= p0_stage_done ? one_hot_sel_791 : ____state_4;
      ____state_1 <= and_804 ? t__stream_id_select : ____state_1;
      __t__unified_pld_reg <= t__unified_pld_load_en ? t__unified_pld : __t__unified_pld_reg;
      __t__unified_pld_valid_reg <= t__unified_pld_valid_load_en ? t__unified_pld_vld : __t__unified_pld_valid_reg;
      __t__stream_id_reg <= t__stream_id_load_en ? t__stream_id : __t__stream_id_reg;
      __t__stream_id_valid_reg <= t__stream_id_valid_load_en ? t__stream_id_vld : __t__stream_id_valid_reg;
      __t__accumulation_addr_reg <= t__accumulation_addr_load_en ? update_pld : __t__accumulation_addr_reg;
      __t__accumulation_addr_valid_reg <= t__accumulation_addr_valid_load_en ? __t__accumulation_addr_vld_buf : __t__accumulation_addr_valid_reg;
      __t__payload_type_four_reg <= t__payload_type_four_load_en ? stream_pld : __t__payload_type_four_reg;
      __t__payload_type_four_valid_reg <= t__payload_type_four_valid_load_en ? __t__payload_type_four_vld_buf : __t__payload_type_four_valid_reg;
    end
  end
  assign t__accumulation_addr = __t__accumulation_addr_reg;
  assign t__accumulation_addr_vld = __t__accumulation_addr_valid_reg;
  assign t__payload_type_four = __t__payload_type_four_reg;
  assign t__payload_type_four_vld = __t__payload_type_four_valid_reg;
  assign t__stream_id_rdy = t__stream_id_load_en;
  assign t__unified_pld_rdy = t__unified_pld_load_en;
  `ifdef ASSERT_ON
  ____state_2__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_860))) or_860) else $fatal(0, "More than one next_value fired for state element: __state_2");
  ____state_3__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_860))) or_860) else $fatal(0, "More than one next_value fired for state element: __state_3");
  ____state_4__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_860))) or_860) else $fatal(0, "More than one next_value fired for state element: __state_4");
  ____state_0__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_866))) or_866) else $fatal(0, "More than one next_value fired for state element: __state_0");
  `endif  // ASSERT_ON
endmodule
`default_nettype wire
