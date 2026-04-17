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
  function automatic [31:0] smul32b_32b_x_32b (input reg [31:0] lhs, input reg [31:0] rhs);
    reg signed [31:0] signed_lhs;
    reg signed [31:0] signed_rhs;
    reg signed [31:0] signed_result;
    begin
      signed_lhs = $signed(lhs);
      signed_rhs = $signed(rhs);
      signed_result = signed_lhs * signed_rhs;
      smul32b_32b_x_32b = $unsigned(signed_result);
    end
  endfunction
  // lint_on MULTIPLY
  // lint_on SIGNED_TYPE
  wire [63:0] ____state_2_init[5];
  assign ____state_2_init = '{64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000};
  wire [127:0] __t__unified_pld_reg_init = {2'h0, 30'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] __t__accumulation_addr_reg_init = {1'h0, 2'h0, 29'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [127:0] literal_772 = {2'h0, 30'h0000_0000, 32'h0000_0000, 32'h0000_0000, 32'h0000_0000};
  wire [63:0] new_queue[5];
  assign new_queue = '{64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000, 64'h0000_0000_0000_0000};
  reg ____state_0;
  reg [63:0] ____state_2[5];
  reg ____state_4;
  reg [31:0] ____state_1;
  reg p0_valid;
  reg p1_valid;
  reg [127:0] __t__unified_pld_reg;
  reg __t__unified_pld_valid_reg;
  reg [31:0] __t__stream_id_reg;
  reg __t__stream_id_valid_reg;
  reg [127:0] __t__accumulation_addr_reg;
  reg __t__accumulation_addr_valid_reg;
  reg [63:0] __t__payload_type_four_reg;
  reg __t__payload_type_four_valid_reg;
  wire [127:0] t__unified_pld_select;
  wire [63:0] array_index_775;
  wire [1:0] spld_commands__2;
  wire [63:0] element__4;
  wire [29:0] spld_addr;
  wire [63:0] element__3;
  wire accumulate;
  wire [63:0] element__2;
  wire match_pred;
  wire [31:0] spld_mem_base;
  wire p0_all_active_inputs_valid;
  wire and_841;
  wire t__accumulation_addr_valid_inv;
  wire and_857;
  wire t__payload_type_four_valid_inv;
  wire [63:0] element__1;
  wire match_pred__1;
  wire [31:0] n_base;
  wire __t__accumulation_addr_vld_buf;
  wire t__accumulation_addr_valid_load_en;
  wire __t__payload_type_four_vld_buf;
  wire t__payload_type_four_valid_load_en;
  wire new_state__1_1_case_cmp;
  wire match_pred__2;
  wire [31:0] n_base__1;
  wire t__accumulation_addr_not_pred;
  wire t__accumulation_addr_load_en;
  wire t__payload_type_four_not_pred;
  wire t__payload_type_four_load_en;
  wire nor_822;
  wire and_823;
  wire match_pred__3;
  wire [31:0] n_base__2;
  wire [1:0] ____state_2__next_value_predicates;
  wire [2:0] ____state_0__next_value_predicates;
  wire match_pred__4;
  wire [31:0] n_base__3;
  wire [31:0] spld_matrix_val__1;
  wire [31:0] spld_vector_val;
  wire p0_all_active_outputs_ready;
  wire [2:0] one_hot_836;
  wire [3:0] one_hot_837;
  wire [31:0] base;
  wire [31:0] incr;
  wire p0_stage_done;
  wire new_seen_sod;
  wire [31:0] add_833;
  wire and_915;
  wire t__stream_id_valid_inv;
  wire and_919;
  wire t__unified_pld_valid_inv;
  wire [63:0] update;
  wire and_931;
  wire and_932;
  wire t__stream_id_valid_load_en;
  wire t__unified_pld_valid_load_en;
  wire ____state_2__at_most_one_next_value;
  wire ____state_0__at_most_one_next_value;
  wire [1:0] concat_920;
  wire [63:0] new_queue__1[5];
  wire new_seen_sod__1;
  wire [2:0] concat_933;
  wire unexpand_for_next_value_158_0_case_0;
  wire [28:0] add_842;
  wire t__stream_id_load_en;
  wire t__unified_pld_load_en;
  wire or_984;
  wire or_990;
  wire p1_enable;
  wire p0_enable;
  wire [31:0] t__stream_id_select;
  wire [63:0] one_hot_sel_921[5];
  wire or_922;
  wire one_hot_sel_927;
  wire one_hot_sel_934;
  wire or_935;
  wire [127:0] update_pld;
  wire [63:0] stream_pld;
  assign t__unified_pld_select = ____state_0 ? __t__unified_pld_reg : literal_772;
  assign array_index_775 = ____state_2[3'h4];
  assign spld_commands__2 = t__unified_pld_select[127:126];
  assign element__4 = ____state_2[3'h3];
  assign spld_addr = t__unified_pld_select[125:96];
  assign element__3 = ____state_2[3'h2];
  assign accumulate = ~(spld_commands__2[0] | spld_commands__2[1] | ____state_4);
  assign element__2 = ____state_2[3'h1];
  assign match_pred = array_index_775[63:62] == 2'h1 & array_index_775[61:32] == spld_addr;
  assign spld_mem_base = t__unified_pld_select[31:0];
  assign p0_all_active_inputs_valid = (~____state_0 | __t__unified_pld_valid_reg) & (____state_0 | __t__stream_id_valid_reg);
  assign and_841 = ____state_0 & accumulate;
  assign t__accumulation_addr_valid_inv = ~__t__accumulation_addr_valid_reg;
  assign and_857 = ____state_0 & (spld_commands__2[0] | spld_commands__2[1] | ____state_4);
  assign t__payload_type_four_valid_inv = ~__t__payload_type_four_valid_reg;
  assign element__1 = ____state_2[3'h0];
  assign match_pred__1 = element__4[63:62] == 2'h1 & element__4[61:32] == spld_addr;
  assign n_base = match_pred ? array_index_775[31:0] : spld_mem_base;
  assign __t__accumulation_addr_vld_buf = p0_all_active_inputs_valid & and_841;
  assign t__accumulation_addr_valid_load_en = t__accumulation_addr_rdy | t__accumulation_addr_valid_inv;
  assign __t__payload_type_four_vld_buf = p0_all_active_inputs_valid & and_857;
  assign t__payload_type_four_valid_load_en = t__payload_type_four_rdy | t__payload_type_four_valid_inv;
  assign new_state__1_1_case_cmp = spld_commands__2 == 2'h3;
  assign match_pred__2 = element__3[63:62] == 2'h1 & element__3[61:32] == spld_addr;
  assign n_base__1 = match_pred__1 ? element__4[31:0] : n_base;
  assign t__accumulation_addr_not_pred = ~and_841;
  assign t__accumulation_addr_load_en = __t__accumulation_addr_vld_buf & t__accumulation_addr_valid_load_en;
  assign t__payload_type_four_not_pred = ~and_857;
  assign t__payload_type_four_load_en = __t__payload_type_four_vld_buf & t__payload_type_four_valid_load_en;
  assign nor_822 = ~(~____state_0 | new_state__1_1_case_cmp);
  assign and_823 = ____state_0 & new_state__1_1_case_cmp;
  assign match_pred__3 = element__2[63:62] == 2'h1 & element__2[61:32] == spld_addr;
  assign n_base__2 = match_pred__2 ? element__3[31:0] : n_base__1;
  assign ____state_2__next_value_predicates = {~____state_0, ____state_0};
  assign ____state_0__next_value_predicates = {~____state_0, nor_822, and_823};
  assign match_pred__4 = element__1[63:62] == 2'h1 & element__1[61:32] == spld_addr;
  assign n_base__3 = match_pred__3 ? element__2[31:0] : n_base__2;
  assign spld_matrix_val__1 = t__unified_pld_select[95:64];
  assign spld_vector_val = t__unified_pld_select[63:32];
  assign p0_all_active_outputs_ready = (t__accumulation_addr_not_pred | t__accumulation_addr_load_en) & (t__payload_type_four_not_pred | t__payload_type_four_load_en);
  assign one_hot_836 = {____state_2__next_value_predicates[1:0] == 2'h0, ____state_2__next_value_predicates[1] && !____state_2__next_value_predicates[0], ____state_2__next_value_predicates[0]};
  assign one_hot_837 = {____state_0__next_value_predicates[2:0] == 3'h0, ____state_0__next_value_predicates[2] && ____state_0__next_value_predicates[1:0] == 2'h0, ____state_0__next_value_predicates[1] && !____state_0__next_value_predicates[0], ____state_0__next_value_predicates[0]};
  assign base = match_pred__4 ? element__1[31:0] : n_base__3;
  assign incr = smul32b_32b_x_32b(spld_matrix_val__1, spld_vector_val);
  assign p0_stage_done = p0_all_active_inputs_valid & p0_all_active_outputs_ready;
  assign new_seen_sod = 1'h0;
  assign add_833 = base + incr;
  assign and_915 = ~____state_0 & p0_stage_done;
  assign t__stream_id_valid_inv = ~__t__stream_id_valid_reg;
  assign and_919 = ____state_0 & p0_stage_done;
  assign t__unified_pld_valid_inv = ~__t__unified_pld_valid_reg;
  assign update = {new_seen_sod, spld_matrix_val__1 != 32'h0000_0000, spld_addr, add_833};
  assign and_931 = nor_822 & p0_stage_done;
  assign and_932 = and_823 & p0_stage_done;
  assign t__stream_id_valid_load_en = and_915 | t__stream_id_valid_inv;
  assign t__unified_pld_valid_load_en = and_919 | t__unified_pld_valid_inv;
  assign ____state_2__at_most_one_next_value = ~____state_0 == one_hot_836[1] & ____state_0 == one_hot_836[0];
  assign ____state_0__at_most_one_next_value = ~____state_0 == one_hot_837[2] & nor_822 == one_hot_837[1] & and_823 == one_hot_837[0];
  assign concat_920 = {and_915, and_919};
  assign new_queue__1[0] = update;
  assign new_queue__1[1] = element__1;
  assign new_queue__1[2] = element__2;
  assign new_queue__1[3] = element__3;
  assign new_queue__1[4] = element__4;
  assign new_seen_sod__1 = spld_commands__2 == 2'h1 | ____state_4;
  assign concat_933 = {and_915, and_931, and_932};
  assign unexpand_for_next_value_158_0_case_0 = 1'h1;
  assign add_842 = spld_addr[28:0] + ____state_1[29:1];
  assign t__stream_id_load_en = t__stream_id_vld & t__stream_id_valid_load_en;
  assign t__unified_pld_load_en = t__unified_pld_vld & t__unified_pld_valid_load_en;
  assign or_984 = ~p0_stage_done | ____state_2__at_most_one_next_value | rst;
  assign or_990 = ~p0_stage_done | ____state_0__at_most_one_next_value | rst;
  assign p1_enable = 1'h1;
  assign p0_enable = 1'h1;
  assign t__stream_id_select = ~____state_0 ? __t__stream_id_reg : 32'h0000_0000;
  assign one_hot_sel_921[0] = new_queue__1[0] & {64{concat_920[0]}} | new_queue[0] & {64{concat_920[1]}};
  assign one_hot_sel_921[1] = new_queue__1[1] & {64{concat_920[0]}} | new_queue[1] & {64{concat_920[1]}};
  assign one_hot_sel_921[2] = new_queue__1[2] & {64{concat_920[0]}} | new_queue[2] & {64{concat_920[1]}};
  assign one_hot_sel_921[3] = new_queue__1[3] & {64{concat_920[0]}} | new_queue[3] & {64{concat_920[1]}};
  assign one_hot_sel_921[4] = new_queue__1[4] & {64{concat_920[0]}} | new_queue[4] & {64{concat_920[1]}};
  assign or_922 = and_915 | and_919;
  assign one_hot_sel_927 = new_seen_sod__1 & concat_920[0] | new_seen_sod & concat_920[1];
  assign one_hot_sel_934 = new_seen_sod & concat_933[0] | unexpand_for_next_value_158_0_case_0 & concat_933[1] | unexpand_for_next_value_158_0_case_0 & concat_933[2];
  assign or_935 = and_915 | and_931 | and_932;
  assign update_pld = {unexpand_for_next_value_158_0_case_0, 2'h0, spld_addr[28:0], add_833, 32'h0000_0000, 32'h0000_0000};
  assign stream_pld = {spld_commands__2, add_842, ____state_1[0], spld_mem_base};
  always_ff @ (posedge clk) begin
    if (rst) begin
      ____state_0 <= 1'h0;
      ____state_2 <= ____state_2_init;
      ____state_4 <= 1'h0;
      ____state_1 <= 32'h0000_0000;
      p0_valid <= 1'h0;
      p1_valid <= 1'h0;
      __t__unified_pld_reg <= __t__unified_pld_reg_init;
      __t__unified_pld_valid_reg <= 1'h0;
      __t__stream_id_reg <= 32'h0000_0000;
      __t__stream_id_valid_reg <= 1'h0;
      __t__accumulation_addr_reg <= __t__accumulation_addr_reg_init;
      __t__accumulation_addr_valid_reg <= 1'h0;
      __t__payload_type_four_reg <= 64'h0000_0000_0000_0000;
      __t__payload_type_four_valid_reg <= 1'h0;
    end else begin
      ____state_0 <= or_935 ? one_hot_sel_934 : ____state_0;
      ____state_2 <= or_922 ? one_hot_sel_921 : ____state_2;
      ____state_4 <= or_922 ? one_hot_sel_927 : ____state_4;
      ____state_1 <= and_915 ? t__stream_id_select : ____state_1;
      p0_valid <= p0_enable ? p0_stage_done : p0_valid;
      p1_valid <= p1_enable ? p0_valid : p1_valid;
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
  ____state_2__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_984))) or_984) else $fatal(0, "More than one next_value fired for state element: __state_2");
  ____state_3__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_984))) or_984) else $fatal(0, "More than one next_value fired for state element: __state_3");
  ____state_4__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_984))) or_984) else $fatal(0, "More than one next_value fired for state element: __state_4");
  ____state_0__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_990))) or_990) else $fatal(0, "More than one next_value fired for state element: __state_0");
  `endif  // ASSERT_ON
endmodule
