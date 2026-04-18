`default_nettype none
module __t__clusters_results_merger_0_next(
  input wire clk,
  input wire rst,
  input wire [95:0] t__multistream_vector_payload_one__0,
  input wire t__multistream_vector_payload_one__0_vld,
  input wire t__vector_payload_one_rdy,
  output wire t__multistream_vector_payload_one__0_rdy,
  output wire [95:0] t__vector_payload_one,
  output wire t__vector_payload_one_vld
);
  reg [95:0] ____state_5;
  reg [1:0] ____state_0;
  reg ____state_3;
  reg [29:0] ____state_2;
  reg [95:0] __t__multistream_vector_payload_one__0_reg;
  reg __t__multistream_vector_payload_one__0_valid_reg;
  reg [95:0] __t__vector_payload_one_reg;
  reg __t__vector_payload_one_valid_reg;
  wire [1:0] unexpand_for_next_value_202_0__1_case_1_case_1;
  wire [1:0] unexpand_for_next_value_202_0__1_case_0;
  wire st2_predicate_piece_0;
  wire st2_2_case_cmp;
  wire st2_1_case_cmp;
  wire got_eos__1;
  wire [2:0] st2_predicate_piece_2;
  wire or_893;
  wire vpo_tx;
  wire t__vector_payload_one_valid_inv;
  wire or_830;
  wire new_state__1_1_case_cmp;
  wire __t__vector_payload_one_vld_buf;
  wire t__vector_payload_one_valid_load_en;
  wire nor_833;
  wire and_834;
  wire and_835;
  wire nor_837;
  wire and_838;
  wire t__vector_payload_one_load_en;
  wire [1:0] ____state_2__next_value_predicates;
  wire [1:0] ____state_3__next_value_predicates;
  wire [3:0] ____state_0__next_value_predicates;
  wire [2:0] one_hot_849;
  wire [2:0] one_hot_850;
  wire [4:0] one_hot_851;
  wire [1:0] concat_844;
  wire p0_stage_done;
  wire [2:0] one_hot_961;
  wire [3:0] one_hot_967;
  wire and_934;
  wire t__multistream_vector_payload_one__0_valid_inv;
  wire and_900;
  wire t__multistream_vector_payload_one__0_valid_load_en;
  wire ____state_2__at_most_one_next_value;
  wire ____state_3__at_most_one_next_value;
  wire ____state_0__at_most_one_next_value;
  wire [1:0] concat_903;
  wire [29:0] payload_index_incremented;
  wire [29:0] new_payload_index__1;
  wire [1:0] concat_910;
  wire [3:0] concat_922;
  wire [1:0] unexpand_for_next_value_202_0__1_case_2;
  wire t__multistream_vector_payload_one__0_load_en;
  wire or_974;
  wire or_976;
  wire or_978;
  wire [29:0] one_hot_sel_904;
  wire and_929;
  wire one_hot_sel_911;
  wire and_932;
  wire [95:0] t__multistream_vector_payload_one__0_select;
  wire [1:0] one_hot_sel_923;
  wire and_937;
  wire [95:0] vpo_pld;
  wire or_980;
  wire or_982;
  assign unexpand_for_next_value_202_0__1_case_1_case_1 = 2'h2;
  assign unexpand_for_next_value_202_0__1_case_0 = 2'h1;
  assign st2_predicate_piece_0 = ~(____state_0[0] | ____state_0[1]);
  assign st2_2_case_cmp = ____state_0 == unexpand_for_next_value_202_0__1_case_1_case_1;
  assign st2_1_case_cmp = ____state_0 == unexpand_for_next_value_202_0__1_case_0;
  assign got_eos__1 = ____state_5[95:94] == 2'h3;
  assign st2_predicate_piece_2 = {st2_2_case_cmp, st2_1_case_cmp, st2_predicate_piece_0};
  assign or_893 = ~st2_predicate_piece_0 | __t__multistream_vector_payload_one__0_valid_reg;
  assign vpo_tx = 1'h0 & st2_predicate_piece_2[0] | ~got_eos__1 & st2_predicate_piece_2[1] | 1'h1 & st2_predicate_piece_2[2];
  assign t__vector_payload_one_valid_inv = ~__t__vector_payload_one_valid_reg;
  assign or_830 = ____state_0[0] | ____state_0[1];
  assign new_state__1_1_case_cmp = got_eos__1 | ____state_3;
  assign __t__vector_payload_one_vld_buf = or_893 & vpo_tx;
  assign t__vector_payload_one_valid_load_en = t__vector_payload_one_rdy | t__vector_payload_one_valid_inv;
  assign nor_833 = ~(~st2_1_case_cmp | ____state_5[94] | ____state_5[95]);
  assign and_834 = st2_1_case_cmp & or_830;
  assign and_835 = st2_2_case_cmp & ~st2_1_case_cmp & or_830;
  assign nor_837 = ~(~st2_1_case_cmp | got_eos__1 | ____state_3);
  assign and_838 = st2_1_case_cmp & new_state__1_1_case_cmp;
  assign t__vector_payload_one_load_en = __t__vector_payload_one_vld_buf & t__vector_payload_one_valid_load_en;
  assign ____state_2__next_value_predicates = {st2_2_case_cmp, nor_833};
  assign ____state_3__next_value_predicates = {and_834, and_835};
  assign ____state_0__next_value_predicates = {st2_predicate_piece_0, st2_2_case_cmp, nor_837, and_838};
  assign one_hot_849 = {____state_2__next_value_predicates[1:0] == 2'h0, ____state_2__next_value_predicates[1] && !____state_2__next_value_predicates[0], ____state_2__next_value_predicates[0]};
  assign one_hot_850 = {____state_3__next_value_predicates[1:0] == 2'h0, ____state_3__next_value_predicates[1] && !____state_3__next_value_predicates[0], ____state_3__next_value_predicates[0]};
  assign one_hot_851 = {____state_0__next_value_predicates[3:0] == 4'h0, ____state_0__next_value_predicates[3] && ____state_0__next_value_predicates[2:0] == 3'h0, ____state_0__next_value_predicates[2] && ____state_0__next_value_predicates[1:0] == 2'h0, ____state_0__next_value_predicates[1] && !____state_0__next_value_predicates[0], ____state_0__next_value_predicates[0]};
  assign concat_844 = {st2_2_case_cmp, st2_1_case_cmp};
  assign p0_stage_done = or_893 & (~vpo_tx | t__vector_payload_one_load_en);
  assign one_hot_961 = {concat_844[1:0] == 2'h0, concat_844[1] && !concat_844[0], concat_844[0]};
  assign one_hot_967 = {st2_predicate_piece_2[2:0] == 3'h0, st2_predicate_piece_2[2] && st2_predicate_piece_2[1:0] == 2'h0, st2_predicate_piece_2[1] && !st2_predicate_piece_2[0], st2_predicate_piece_2[0]};
  assign and_934 = st2_predicate_piece_0 & p0_stage_done;
  assign t__multistream_vector_payload_one__0_valid_inv = ~__t__multistream_vector_payload_one__0_valid_reg;
  assign and_900 = st2_2_case_cmp & p0_stage_done;
  assign t__multistream_vector_payload_one__0_valid_load_en = and_934 | t__multistream_vector_payload_one__0_valid_inv;
  assign ____state_2__at_most_one_next_value = st2_2_case_cmp == one_hot_849[1] & nor_833 == one_hot_849[0];
  assign ____state_3__at_most_one_next_value = and_834 == one_hot_850[1] & and_835 == one_hot_850[0];
  assign ____state_0__at_most_one_next_value = st2_predicate_piece_0 == one_hot_851[3] & st2_2_case_cmp == one_hot_851[2] & nor_837 == one_hot_851[1] & and_838 == one_hot_851[0];
  assign concat_903 = {and_900, nor_833 & p0_stage_done};
  assign payload_index_incremented = ____state_2 + 30'h0000_0001;
  assign new_payload_index__1 = 30'h0000_0000;
  assign concat_910 = {and_834 & p0_stage_done, and_835 & p0_stage_done};
  assign concat_922 = {st2_predicate_piece_0 & p0_stage_done, and_900, nor_837 & p0_stage_done, and_838 & p0_stage_done};
  assign unexpand_for_next_value_202_0__1_case_2 = 2'h0;
  assign t__multistream_vector_payload_one__0_load_en = t__multistream_vector_payload_one__0_vld & t__multistream_vector_payload_one__0_valid_load_en;
  assign or_974 = ~p0_stage_done | ____state_2__at_most_one_next_value | rst;
  assign or_976 = ~p0_stage_done | ____state_3__at_most_one_next_value | rst;
  assign or_978 = ~p0_stage_done | ____state_0__at_most_one_next_value | rst;
  assign one_hot_sel_904 = payload_index_incremented & {30{concat_903[0]}} | new_payload_index__1 & {30{concat_903[1]}};
  assign and_929 = (st2_2_case_cmp | nor_833) & p0_stage_done;
  assign one_hot_sel_911 = 1'h0 & concat_910[0] | new_state__1_1_case_cmp & concat_910[1];
  assign and_932 = (and_834 | and_835) & p0_stage_done;
  assign t__multistream_vector_payload_one__0_select = st2_predicate_piece_0 ? __t__multistream_vector_payload_one__0_reg : 96'h0000_0000_0000_0000_0000_0000;
  assign one_hot_sel_923 = unexpand_for_next_value_202_0__1_case_1_case_1 & {2{concat_922[0]}} | unexpand_for_next_value_202_0__1_case_2 & {2{concat_922[1]}} | unexpand_for_next_value_202_0__1_case_2 & {2{concat_922[2]}} | unexpand_for_next_value_202_0__1_case_0 & {2{concat_922[3]}};
  assign and_937 = (st2_predicate_piece_0 | st2_2_case_cmp | nor_837 | and_838) & p0_stage_done;
  assign vpo_pld = {____state_5[95:94], ____state_2, ____state_5[63:0]} & {96{concat_844[0]}} | 96'hc000_0000_0000_0000_0000_0000 & {96{concat_844[1]}};
  assign or_980 = ~p0_stage_done | concat_844 == one_hot_961[1:0] | rst;
  assign or_982 = ~p0_stage_done | st2_predicate_piece_2 == one_hot_967[2:0] | rst;
  always_ff @ (posedge clk) begin
    if (rst) begin
      ____state_5 <= 96'h0000_0000_0000_0000_0000_0000;
      ____state_0 <= 2'h0;
      ____state_3 <= 1'h0;
      ____state_2 <= 30'h0000_0000;
      __t__multistream_vector_payload_one__0_reg <= 96'h0000_0000_0000_0000_0000_0000;
      __t__multistream_vector_payload_one__0_valid_reg <= 1'h0;
      __t__vector_payload_one_reg <= 96'h0000_0000_0000_0000_0000_0000;
      __t__vector_payload_one_valid_reg <= 1'h0;
    end else begin
      ____state_5 <= and_934 ? t__multistream_vector_payload_one__0_select : ____state_5;
      ____state_0 <= and_937 ? one_hot_sel_923 : ____state_0;
      ____state_3 <= and_932 ? one_hot_sel_911 : ____state_3;
      ____state_2 <= and_929 ? one_hot_sel_904 : ____state_2;
      __t__multistream_vector_payload_one__0_reg <= t__multistream_vector_payload_one__0_load_en ? t__multistream_vector_payload_one__0 : __t__multistream_vector_payload_one__0_reg;
      __t__multistream_vector_payload_one__0_valid_reg <= t__multistream_vector_payload_one__0_valid_load_en ? t__multistream_vector_payload_one__0_vld : __t__multistream_vector_payload_one__0_valid_reg;
      __t__vector_payload_one_reg <= t__vector_payload_one_load_en ? vpo_pld : __t__vector_payload_one_reg;
      __t__vector_payload_one_valid_reg <= t__vector_payload_one_valid_load_en ? __t__vector_payload_one_vld_buf : __t__vector_payload_one_valid_reg;
    end
  end
  assign t__multistream_vector_payload_one__0_rdy = t__multistream_vector_payload_one__0_load_en;
  assign t__vector_payload_one = __t__vector_payload_one_reg;
  assign t__vector_payload_one_vld = __t__vector_payload_one_valid_reg;
  `ifdef ASSERT_ON
  ____state_2__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_974))) or_974) else $fatal(0, "More than one next_value fired for state element: __state_2");
  ____state_3__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_976))) or_976) else $fatal(0, "More than one next_value fired for state element: __state_3");
  ____state_0__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_978))) or_978) else $fatal(0, "More than one next_value fired for state element: __state_0");
  __xls_invariant_vpo_pld_selector_one_hot_A: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_980))) or_980) else $fatal(0, "Selector concat.844 was expected to be one-hot, and is not.");
  __xls_invariant_vpo_tx_selector_one_hot_A: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_982))) or_982) else $fatal(0, "Selector st2_predicate_piece_2 was expected to be one-hot, and is not.");
  `endif  // ASSERT_ON
endmodule
`default_nettype wire
