module __example__example_0_next(
  input wire clk,
  input wire rst,
  input wire example__addr_rdy,
  input wire [31:0] example__pld,
  input wire example__pld_vld,
  output wire [31:0] example__addr,
  output wire example__addr_vld,
  output wire example__pld_rdy
);
  reg [1:0] p0___state_0;
  reg p0_eq_214;
  reg p1_eq_214;
  reg p0_nor_228;
  reg p1_nor_228;
  reg p1_or_273;
  reg ____state_1_full;
  reg __implicit_token__receive_16_full;
  reg __implicit_token__receive_32_full;
  reg __implicit_token__new_tok_full;
  reg __implicit_token__new_tok__2_full;
  reg [1:0] ____state_0;
  reg ____state_0_full;
  reg __example__addr_valid_reg;
  reg __example__pld_valid_reg;
  reg p1_inputs_valid;
  reg p2_inputs_valid;
  wire or_498;
  wire example__addr_valid_inv;
  wire __example__addr_vld_buf;
  wire example__addr_valid_load_en;
  wire example__addr_load_en;
  wire active_inputs_valid_2;
  wire [1:0] unexpand_for_next_value_41_0_case_0;
  wire stage_outputs_valid_2;
  wire nor_532;
  wire eq_533;
  wire stage_outputs_valid_1;
  wire stage_outputs_ready_1;
  wire [1:0] ____state_1__next_value_predicates;
  wire p1_stage_done__1;
  wire [2:0] one_hot_543;
  wire stage_outputs_valid_0;
  wire stage_outputs_ready_0;
  wire nor_548;
  wire p0_stage_done;
  wire and_558;
  wire and_702;
  wire and_703;
  wire and_561;
  wire and_563;
  wire example__pld_valid_inv;
  wire ____state_1__at_most_one_next_value;
  wire or_590;
  wire or_592;
  wire or_594;
  wire or_596;
  wire or_598;
  wire [2:0] concat_599;
  wire [1:0] unexpand_for_next_value_41_0_case_1;
  wire or_603;
  wire example__pld_valid_load_en;
  wire or_609;
  wire or_618;
  wire or_619;
  wire or_620;
  wire or_621;
  wire or_622;
  wire [1:0] one_hot_sel_623;
  wire or_624;
  wire [31:0] __example__addr_reg;
  wire example__pld_load_en;
  wire or_629;
  wire or_630;
  assign or_498 = p0_nor_228 | p0_eq_214;
  assign example__addr_valid_inv = ~__example__addr_valid_reg;
  assign __example__addr_vld_buf = p1_inputs_valid & or_498;
  assign example__addr_valid_load_en = example__addr_rdy | example__addr_valid_inv;
  assign example__addr_load_en = __example__addr_vld_buf & example__addr_valid_load_en;
  assign active_inputs_valid_2 = __example__pld_valid_reg | ~p1_or_273;
  assign unexpand_for_next_value_41_0_case_0 = 2'h1;
  assign stage_outputs_valid_2 = p2_inputs_valid & active_inputs_valid_2;
  assign nor_532 = ~(____state_0[0] | ____state_0[1]);
  assign eq_533 = ____state_0 == unexpand_for_next_value_41_0_case_0;
  assign stage_outputs_valid_1 = p1_inputs_valid & (example__addr_load_en | ~or_498);
  assign stage_outputs_ready_1 = ~p2_inputs_valid | stage_outputs_valid_2;
  assign ____state_1__next_value_predicates = {nor_532, eq_533};
  assign p1_stage_done__1 = stage_outputs_valid_1 & stage_outputs_ready_1;
  assign one_hot_543 = {____state_1__next_value_predicates[1:0] == 2'h0, ____state_1__next_value_predicates[1] && !____state_1__next_value_predicates[0], ____state_1__next_value_predicates[0]};
  assign stage_outputs_valid_0 = ____state_1_full & __implicit_token__receive_16_full & __implicit_token__receive_32_full & __implicit_token__new_tok_full & __implicit_token__new_tok__2_full & ____state_0_full;
  assign stage_outputs_ready_0 = ~p1_inputs_valid | p1_stage_done__1;
  assign nor_548 = ~(p0_eq_214 | p0_nor_228);
  assign p0_stage_done = stage_outputs_valid_0 & stage_outputs_ready_0;
  assign and_558 = stage_outputs_valid_1 & stage_outputs_ready_1 & nor_548;
  assign and_702 = stage_outputs_valid_2 & p1_nor_228;
  assign and_703 = stage_outputs_valid_2 & p1_eq_214;
  assign and_561 = stage_outputs_valid_0 & stage_outputs_ready_0 & (____state_0[0] | ____state_0[1]);
  assign and_563 = stage_outputs_valid_0 & stage_outputs_ready_0 & ~eq_533;
  assign example__pld_valid_inv = ~__example__pld_valid_reg;
  assign ____state_1__at_most_one_next_value = nor_532 == one_hot_543[1] & eq_533 == one_hot_543[0];
  assign or_590 = and_558 | and_702 | and_703;
  assign or_592 = and_561 | and_702;
  assign or_594 = and_563 | and_703;
  assign or_596 = and_561 | stage_outputs_valid_1 & stage_outputs_ready_1 & p0_nor_228;
  assign or_598 = and_563 | stage_outputs_valid_1 & stage_outputs_ready_1 & p0_eq_214;
  assign concat_599 = {stage_outputs_valid_0 & nor_532, stage_outputs_valid_0 & eq_533, p1_inputs_valid & nor_548};
  assign unexpand_for_next_value_41_0_case_1 = 2'h2;
  assign or_603 = stage_outputs_valid_0 & stage_outputs_ready_0 & nor_532 | stage_outputs_valid_0 & stage_outputs_ready_0 & eq_533 | and_558;
  assign example__pld_valid_load_en = stage_outputs_valid_2 & p1_or_273 | example__pld_valid_inv;
  assign or_609 = ~p0_stage_done | ____state_1__at_most_one_next_value | rst;
  assign or_618 = p0_stage_done | or_590;
  assign or_619 = p0_stage_done | or_592;
  assign or_620 = p0_stage_done | or_594;
  assign or_621 = p0_stage_done | or_596;
  assign or_622 = p0_stage_done | or_598;
  assign one_hot_sel_623 = p0___state_0 & {2{concat_599[0]}} | unexpand_for_next_value_41_0_case_1 & {2{concat_599[1]}} | unexpand_for_next_value_41_0_case_0 & {2{concat_599[2]}};
  assign or_624 = p0_stage_done | or_603;
  assign __example__addr_reg = 32'h0000_0000;
  assign example__pld_load_en = example__pld_vld & example__pld_valid_load_en;
  assign or_629 = p0_stage_done | p1_stage_done__1;
  assign or_630 = p1_stage_done__1 | stage_outputs_valid_2;
  always_ff @ (posedge clk) begin
    if (rst) begin
      p0___state_0 <= 2'h0;
      p0_eq_214 <= 1'h0;
      p1_eq_214 <= 1'h0;
      p0_nor_228 <= 1'h0;
      p1_nor_228 <= 1'h0;
      p1_or_273 <= 1'h0;
      ____state_1_full <= 1'h1;
      __implicit_token__receive_16_full <= 1'h1;
      __implicit_token__receive_32_full <= 1'h1;
      __implicit_token__new_tok_full <= 1'h1;
      __implicit_token__new_tok__2_full <= 1'h1;
      ____state_0 <= 2'h0;
      ____state_0_full <= 1'h1;
      __example__addr_valid_reg <= 1'h0;
      __example__pld_valid_reg <= 1'h0;
      p1_inputs_valid <= 1'h0;
      p2_inputs_valid <= 1'h0;
    end else begin
      p0___state_0 <= p0_stage_done ? ____state_0 : p0___state_0;
      p0_eq_214 <= p0_stage_done ? eq_533 : p0_eq_214;
      p1_eq_214 <= p1_stage_done__1 ? p0_eq_214 : p1_eq_214;
      p0_nor_228 <= p0_stage_done ? nor_532 : p0_nor_228;
      p1_nor_228 <= p1_stage_done__1 ? p0_nor_228 : p1_nor_228;
      p1_or_273 <= p1_stage_done__1 ? or_498 : p1_or_273;
      ____state_1_full <= or_618 ? or_590 : ____state_1_full;
      __implicit_token__receive_16_full <= or_619 ? or_592 : __implicit_token__receive_16_full;
      __implicit_token__receive_32_full <= or_620 ? or_594 : __implicit_token__receive_32_full;
      __implicit_token__new_tok_full <= or_621 ? or_596 : __implicit_token__new_tok_full;
      __implicit_token__new_tok__2_full <= or_622 ? or_598 : __implicit_token__new_tok__2_full;
      ____state_0 <= or_603 ? one_hot_sel_623 : ____state_0;
      ____state_0_full <= or_624 ? or_603 : ____state_0_full;
      __example__addr_valid_reg <= example__addr_valid_load_en ? __example__addr_vld_buf : __example__addr_valid_reg;
      __example__pld_valid_reg <= example__pld_valid_load_en ? example__pld_vld : __example__pld_valid_reg;
      p1_inputs_valid <= or_629 ? p0_stage_done : p1_inputs_valid;
      p2_inputs_valid <= or_630 ? p1_stage_done__1 : p2_inputs_valid;
    end
  end
  assign example__addr = __example__addr_reg;
  assign example__addr_vld = __example__addr_valid_reg;
  assign example__pld_rdy = example__pld_load_en;
  `ifdef ASSERT_ON
  ____state_1__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_609))) or_609) else $fatal(0, "More than one next_value fired for state element: __state_1");
  ____state_0__at_most_one_next_value_assert: assert property (@(posedge clk) disable iff ($sampled(rst !== 1'h0 || $isunknown(or_609))) or_609) else $fatal(0, "More than one next_value fired for state element: __state_0");
  `endif  // ASSERT_ON
endmodule
