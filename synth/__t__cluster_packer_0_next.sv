`default_nettype none
module __t__cluster_packer_0_next(
  input wire clk,
  input wire rst,
  input wire [63:0] t__payload_type_four__0,
  input wire t__payload_type_four__0_vld,
  input wire [63:0] t__payload_type_four__1,
  input wire t__payload_type_four__1_vld,
  input wire t__vector_payload_one_rdy,
  output wire t__payload_type_four__0_rdy,
  output wire t__payload_type_four__1_rdy,
  output wire [95:0] t__vector_payload_one,
  output wire t__vector_payload_one_vld
);
  wire literal_1381[6];
  assign literal_1381 = '{1'h1, 1'h0, 1'h0, 1'h1, 1'h0, 1'h0};
  wire literal_1393[6];
  assign literal_1393 = '{1'h0, 1'h1, 1'h1, 1'h0, 1'h1, 1'h0};
  reg [2:0] ____state_0;
  reg ____state_2_0;
  reg ____state_2_1;
  reg [63:0] ____state_5_1;
  reg [63:0] ____state_5_0;
  reg ____state_1_0;
  reg ____state_1_1;
  reg [29:0] ____state_3;
  reg [63:0] __t__payload_type_four__1_reg;
  reg __t__payload_type_four__1_valid_reg;
  reg [63:0] __t__payload_type_four__0_reg;
  reg __t__payload_type_four__0_valid_reg;
  reg [95:0] __t__vector_payload_one_reg;
  reg __t__vector_payload_one_valid_reg;
  wire ptf_rx;
  wire [63:0] t__payload_type_four__0_select;
  wire [63:0] t__payload_type_four__1_select;
  wire g_eos;
  wire g_eos__1;
  wire or_1434;
  wire or_1435;
  wire g_sod;
  wire g_sod__1;
  wire [2:0] unexpand_for_next_value_330_0__2_case_1;
  wire got_eos;
  wire or_1443;
  wire or_1444;
  wire [2:0] unexpand_for_next_value_330_0__2_case_3;
  wire ne_1445;
  wire ne_1446;
  wire st0_predicate_piece_0;
  wire new_state_0_case_cmp;
  wire got_sod;
  wire p0_all_active_inputs_valid;
  wire vpo_tx;
  wire t__vector_payload_one_valid_inv;
  wire [2:0] unexpand_for_next_value_330_0__2_case_0_case_1;
  wire [2:0] unexpand_for_next_value_330_0__2_case_0_case_0_case_1;
  wire [2:0] unexpand_for_next_value_330_0__2_case_2;
  wire st0_4_case_cmp;
  wire n_seen__1;
  wire and_1452;
  wire __t__vector_payload_one_vld_buf;
  wire t__vector_payload_one_valid_load_en;
  wire st3_1_case_cmp;
  wire st3_2_case_cmp;
  wire st3_3_case_cmp;
  wire and_1460;
  wire and_1461;
  wire and_1462;
  wire and_1463;
  wire and_1464;
  wire t__vector_payload_one_load_en;
  wire [1:0] ____state_3__next_value_predicates;
  wire [7:0] ____state_0__next_value_predicates;
  wire [2:0] one_hot_1470;
  wire [8:0] one_hot_1471;
  wire [2:0] concat_1468;
  wire p0_stage_done;
  wire [3:0] one_hot_1619;
  wire and_1587;
  wire t__payload_type_four__0_valid_inv;
  wire t__payload_type_four__1_valid_inv;
  wire [95:0] packed_payload;
  wire t__payload_type_four__0_valid_load_en;
  wire t__payload_type_four__1_valid_load_en;
  wire ____state_3__at_most_one_next_value;
  wire ____state_0__at_most_one_next_value;
  wire [1:0] concat_1532;
  wire [29:0] new_pack_idx__1;
  wire [29:0] new_pack_idx;
  wire [7:0] concat_1563;
  wire [95:0] vpo_pld;
  wire t__payload_type_four__0_load_en;
  wire t__payload_type_four__1_load_en;
  wire or_1626;
  wire or_1628;
  wire [29:0] one_hot_sel_1533;
  wire and_1570;
  wire and_1498;
  wire and_1572;
  wire and_1499;
  wire and_1576;
  wire and_1500;
  wire and_1501;
  wire [2:0] one_hot_sel_1564;
  wire and_1585;
  wire [95:0] vpo_pld__1;
  wire or_1630;
  assign ptf_rx = literal_1381[____state_0 > 3'h5 ? 3'h5 : ____state_0];
  assign t__payload_type_four__0_select = ptf_rx ? __t__payload_type_four__0_reg : 64'h0000_0000_0000_0000;
  assign t__payload_type_four__1_select = ptf_rx ? __t__payload_type_four__1_reg : 64'h0000_0000_0000_0000;
  assign g_eos = t__payload_type_four__0_select[63:62] == 2'h3;
  assign g_eos__1 = t__payload_type_four__1_select[63:62] == 2'h3;
  assign or_1434 = g_eos | ____state_2_0;
  assign or_1435 = g_eos__1 | ____state_2_1;
  assign g_sod = t__payload_type_four__0_select[63:62] == 2'h1;
  assign g_sod__1 = t__payload_type_four__1_select[63:62] == 2'h1;
  assign unexpand_for_next_value_330_0__2_case_1 = 3'h0;
  assign got_eos = or_1434 & or_1435;
  assign or_1443 = g_sod | ____state_1_0;
  assign or_1444 = g_sod__1 | ____state_1_1;
  assign unexpand_for_next_value_330_0__2_case_3 = 3'h4;
  assign ne_1445 = ____state_5_1[63:62] != 2'h2;
  assign ne_1446 = ____state_5_0[63:62] != 2'h2;
  assign st0_predicate_piece_0 = ____state_0 == unexpand_for_next_value_330_0__2_case_1;
  assign new_state_0_case_cmp = ~got_eos;
  assign got_sod = or_1443 & or_1444;
  assign p0_all_active_inputs_valid = (~ptf_rx | __t__payload_type_four__1_valid_reg) & (~ptf_rx | __t__payload_type_four__0_valid_reg);
  assign vpo_tx = literal_1393[____state_0 > 3'h5 ? 3'h5 : ____state_0];
  assign t__vector_payload_one_valid_inv = ~__t__vector_payload_one_valid_reg;
  assign unexpand_for_next_value_330_0__2_case_0_case_1 = 3'h1;
  assign unexpand_for_next_value_330_0__2_case_0_case_0_case_1 = 3'h2;
  assign unexpand_for_next_value_330_0__2_case_2 = 3'h3;
  assign st0_4_case_cmp = ____state_0 == unexpand_for_next_value_330_0__2_case_3;
  assign n_seen__1 = ~(ne_1445 & ne_1446);
  assign and_1452 = st0_predicate_piece_0 & new_state_0_case_cmp;
  assign __t__vector_payload_one_vld_buf = p0_all_active_inputs_valid & vpo_tx;
  assign t__vector_payload_one_valid_load_en = t__vector_payload_one_rdy | t__vector_payload_one_valid_inv;
  assign st3_1_case_cmp = ____state_0 == unexpand_for_next_value_330_0__2_case_0_case_1;
  assign st3_2_case_cmp = ____state_0 == unexpand_for_next_value_330_0__2_case_0_case_0_case_1;
  assign st3_3_case_cmp = ____state_0 == unexpand_for_next_value_330_0__2_case_2;
  assign and_1460 = st0_predicate_piece_0 & got_eos;
  assign and_1461 = st0_4_case_cmp & ne_1445 & ne_1446;
  assign and_1462 = st0_4_case_cmp & n_seen__1;
  assign and_1463 = and_1452 & ~got_sod;
  assign and_1464 = and_1452 & got_sod;
  assign t__vector_payload_one_load_en = __t__vector_payload_one_vld_buf & t__vector_payload_one_valid_load_en;
  assign ____state_3__next_value_predicates = {st0_predicate_piece_0, st0_4_case_cmp};
  assign ____state_0__next_value_predicates = {st3_1_case_cmp, st3_2_case_cmp, st3_3_case_cmp, and_1460, and_1461, and_1462, and_1463, and_1464};
  assign one_hot_1470 = {____state_3__next_value_predicates[1:0] == 2'h0, ____state_3__next_value_predicates[1] && !____state_3__next_value_predicates[0], ____state_3__next_value_predicates[0]};
  assign one_hot_1471 = {____state_0__next_value_predicates[7:0] == 8'h00, ____state_0__next_value_predicates[7] && ____state_0__next_value_predicates[6:0] == 7'h00, ____state_0__next_value_predicates[6] && ____state_0__next_value_predicates[5:0] == 6'h00, ____state_0__next_value_predicates[5] && ____state_0__next_value_predicates[4:0] == 5'h00, ____state_0__next_value_predicates[4] && ____state_0__next_value_predicates[3:0] == 4'h0, ____state_0__next_value_predicates[3] && ____state_0__next_value_predicates[2:0] == 3'h0, ____state_0__next_value_predicates[2] && ____state_0__next_value_predicates[1:0] == 2'h0, ____state_0__next_value_predicates[1] && !____state_0__next_value_predicates[0], ____state_0__next_value_predicates[0]};
  assign concat_1468 = {st0_4_case_cmp, st3_2_case_cmp, st3_1_case_cmp};
  assign p0_stage_done = p0_all_active_inputs_valid & (~vpo_tx | t__vector_payload_one_load_en);
  assign one_hot_1619 = {concat_1468[2:0] == 3'h0, concat_1468[2] && concat_1468[1:0] == 2'h0, concat_1468[1] && !concat_1468[0], concat_1468[0]};
  assign and_1587 = p0_stage_done & ptf_rx;
  assign t__payload_type_four__0_valid_inv = ~__t__payload_type_four__0_valid_reg;
  assign t__payload_type_four__1_valid_inv = ~__t__payload_type_four__1_valid_reg;
  assign packed_payload = {2'h0, ____state_3, ____state_5_0[31:0], ____state_5_1[31:0]};
  assign t__payload_type_four__0_valid_load_en = and_1587 | t__payload_type_four__0_valid_inv;
  assign t__payload_type_four__1_valid_load_en = and_1587 | t__payload_type_four__1_valid_inv;
  assign ____state_3__at_most_one_next_value = st0_predicate_piece_0 == one_hot_1470[1] & st0_4_case_cmp == one_hot_1470[0];
  assign ____state_0__at_most_one_next_value = st3_1_case_cmp == one_hot_1471[7] & st3_2_case_cmp == one_hot_1471[6] & st3_3_case_cmp == one_hot_1471[5] & and_1460 == one_hot_1471[4] & and_1461 == one_hot_1471[3] & and_1462 == one_hot_1471[2] & and_1463 == one_hot_1471[1] & and_1464 == one_hot_1471[0];
  assign concat_1532 = {st0_predicate_piece_0 & p0_stage_done, st0_4_case_cmp & p0_stage_done};
  assign new_pack_idx__1 = ____state_3 + 30'h0000_0001;
  assign new_pack_idx = 30'h0000_0000;
  assign concat_1563 = {st3_1_case_cmp & p0_stage_done, st3_2_case_cmp & p0_stage_done, st3_3_case_cmp & p0_stage_done, and_1460 & p0_stage_done, and_1461 & p0_stage_done, and_1462 & p0_stage_done, and_1463 & p0_stage_done, and_1464 & p0_stage_done};
  assign vpo_pld = n_seen__1 ? 96'h8000_0000_0000_0000_0000_0000 : packed_payload;
  assign t__payload_type_four__0_load_en = t__payload_type_four__0_vld & t__payload_type_four__0_valid_load_en;
  assign t__payload_type_four__1_load_en = t__payload_type_four__1_vld & t__payload_type_four__1_valid_load_en;
  assign or_1626 = ~p0_stage_done | ____state_3__at_most_one_next_value | rst;
  assign or_1628 = ~p0_stage_done | ____state_0__at_most_one_next_value | rst;
  assign one_hot_sel_1533 = new_pack_idx__1 & {30{concat_1532[0]}} | new_pack_idx & {30{concat_1532[1]}};
  assign and_1570 = (st0_predicate_piece_0 | st0_4_case_cmp) & p0_stage_done;
  assign and_1498 = ~got_sod & or_1443;
  assign and_1572 = st0_predicate_piece_0 & p0_stage_done;
  assign and_1499 = ~got_sod & or_1444;
  assign and_1576 = st3_3_case_cmp & p0_stage_done;
  assign and_1500 = new_state_0_case_cmp & or_1434;
  assign and_1501 = new_state_0_case_cmp & or_1435;
  assign one_hot_sel_1564 = unexpand_for_next_value_330_0__2_case_0_case_0_case_1 & {3{concat_1563[0]}} | unexpand_for_next_value_330_0__2_case_1 & {3{concat_1563[1]}} | unexpand_for_next_value_330_0__2_case_1 & {3{concat_1563[2]}} | unexpand_for_next_value_330_0__2_case_2 & {3{concat_1563[3]}} | unexpand_for_next_value_330_0__2_case_0_case_1 & {3{concat_1563[4]}} | unexpand_for_next_value_330_0__2_case_3 & {3{concat_1563[5]}} | unexpand_for_next_value_330_0__2_case_2 & {3{concat_1563[6]}} | unexpand_for_next_value_330_0__2_case_1 & {3{concat_1563[7]}};
  assign and_1585 = (st3_1_case_cmp | st3_2_case_cmp | st3_3_case_cmp | and_1460 | and_1461 | and_1462 | and_1463 | and_1464) & p0_stage_done;
  assign vpo_pld__1 = 96'hc000_0000_0000_0000_0000_0000 & {96{concat_1468[0]}} | 96'h4000_0000_0000_0000_0000_0000 & {96{concat_1468[1]}} | vpo_pld & {96{concat_1468[2]}};
  assign or_1630 = ~p0_stage_done | concat_1468 == one_hot_1619[2:0] | rst;
  always_ff @ (posedge clk) begin
    if (rst) begin
      ____state_0 <= 3'h0;
      ____state_2_0 <= 1'h0;
      ____state_2_1 <= 1'h0;
      ____state_5_1 <= 64'h0000_0000_0000_0000;
      ____state_5_0 <= 64'h0000_0000_0000_0000;
      ____state_1_0 <= 1'h0;
      ____state_1_1 <= 1'h0;
      ____state_3 <= 30'h0000_0000;
      __t__payload_type_four__1_reg <= 64'h0000_0000_0000_0000;
      __t__payload_type_four__1_valid_reg <= 1'h0;
      __t__payload_type_four__0_reg <= 64'h0000_0000_0000_0000;
      __t__payload_type_four__0_valid_reg <= 1'h0;
      __t__vector_payload_one_reg <= 96'h0000_0000_0000_0000_0000_0000;
      __t__vector_payload_one_valid_reg <= 1'h0;
    end else begin
      ____state_0 <= and_1585 ? one_hot_sel_1564 : ____state_0;
      ____state_2_0 <= and_1572 ? and_1500 : ____state_2_0;
      ____state_2_1 <= and_1572 ? and_1501 : ____state_2_1;
      ____state_5_1 <= and_1576 ? t__payload_type_four__1_select : ____state_5_1;
      ____state_5_0 <= and_1576 ? t__payload_type_four__0_select : ____state_5_0;
      ____state_1_0 <= and_1572 ? and_1498 : ____state_1_0;
      ____state_1_1 <= and_1572 ? and_1499 : ____state_1_1;
      ____state_3 <= and_1570 ? one_hot_sel_1533 : ____state_3;
      __t__payload_type_four__1_reg <= t__payload_type_four__1_load_en ? t__payload_type_four__1 : __t__payload_type_four__1_reg;
      __t__payload_type_four__1_valid_reg <= t__payload_type_four__1_valid_load_en ? t__payload_type_four__1_vld : __t__payload_type_four__1_valid_reg;
      __t__payload_type_four__0_reg <= t__payload_type_four__0_load_en ? t__payload_type_four__0 : __t__payload_type_four__0_reg;
      __t__payload_type_four__0_valid_reg <= t__payload_type_four__0_valid_load_en ? t__payload_type_four__0_vld : __t__payload_type_four__0_valid_reg;
      __t__vector_payload_one_reg <= t__vector_payload_one_load_en ? vpo_pld__1 : __t__vector_payload_one_reg;
      __t__vector_payload_one_valid_reg <= t__vector_payload_one_valid_load_en ? __t__vector_payload_one_vld_buf : __t__vector_payload_one_valid_reg;
    end
  end
  assign t__payload_type_four__0_rdy = t__payload_type_four__0_load_en;
  assign t__payload_type_four__1_rdy = t__payload_type_four__1_load_en;
  assign t__vector_payload_one = __t__vector_payload_one_reg;
  assign t__vector_payload_one_vld = __t__vector_payload_one_valid_reg;
  `ifdef ASSERT_ON
  ____state_3__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_1626))) or_1626) else $fatal(0, "More than one next_value fired for state element: __state_3");
  ____state_0__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_1628))) or_1628) else $fatal(0, "More than one next_value fired for state element: __state_0");
  __xls_invariant_vpo_pld__1_selector_one_hot_A: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_1630))) or_1630) else $fatal(0, "Selector concat.1468 was expected to be one-hot, and is not.");
  `endif  // ASSERT_ON
endmodule
`default_nettype wire
