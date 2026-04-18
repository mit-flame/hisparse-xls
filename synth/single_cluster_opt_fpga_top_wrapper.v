`default_nettype none
module single_cluster_opt_fpga_top_wrapper(
    input wire clk,
    input wire reset,
    output wire finished,
    output wire [31:0] num_cycles,
    output wire [7:0] [31:0] final_vec,

    // ML BRAM stuff
    output wire [31:0] ml_bram_addr,
    input wire [127:0] ml_bram_dout,
    output wire [31:0] ml_bram_din, // <-- unused
    output wire ml_bram_wea,
    output wire ml_bram_enable,

    // VL BRAM stuff
    output wire [31:0] vl_bram_addr,
    input wire [63:0] vl_bram_dout,
    output wire [31:0] vl_bram_din, // <-- unused
    output wire vl_bram_wea,
    output wire vl_bram_enable,

    // VAU0 BRAM stuff
    output wire [31:0] vau0_bram_addr,
    input wire [31:0] vau0_bram_dout,
    output wire [31:0] vau0_bram_din,
    output wire vau0_bram_wea,
    output wire vau0_bram_enable,

    // VAU1 BRAM stuff
    output wire [31:0] vau1_bram_addr,
    input wire [31:0] vau1_bram_dout,
    output wire [31:0] vau1_bram_din,
    output wire vau1_bram_wea,
    output wire vau1_bram_enable,

    // ----------THESE SHOULD BE TWO PORTS ON THE SAME BRAM------------
    // PE0-Send BRAM stuff
    output wire [31:0] pe0s_bram_addr,
    input wire [31:0] pe0s_bram_dout,
    output wire [31:0] pe0s_bram_din,
    output wire pe0s_bram_wea,
    output wire pe0s_bram_enable,
    // PE0-Recv BRAM stuff
    output wire [31:0] pe0a_bram_addr,
    input wire [31:0] pe0a_bram_dout, // <-- unused
    output wire [31:0] pe0a_bram_din,
    output wire pe0a_bram_wea,
    output wire pe0a_bram_enable,
    // ----------------------------------------------------------------

    // ----------THESE SHOULD BE TWO PORTS ON THE SAME BRAM------------
    // PE1-Send BRAM stuff
    output wire [31:0] pe1s_bram_addr,
    input wire [31:0] pe1s_bram_dout,
    output wire [31:0] pe1s_bram_din,
    output wire pe1s_bram_wea,
    output wire pe1s_bram_enable,
    // PE1-Recv BRAM stuff
    output wire [31:0] pe1a_bram_addr,
    input wire [31:0] pe1a_bram_dout, // <-- unused
    output wire [31:0] pe1a_bram_din,
    output wire pe1a_bram_wea,
    output wire pe1a_bram_enable
    // ----------------------------------------------------------------
);

    single_cluster_opt_fpga_top dut(
        .clk(clk),
        .reset(reset),
        .finished(finished),
        .num_cycles(num_cycles),
        .final_vec(final_vec),

        // ML BRAM stuff
        .ml_bram_addr(ml_bram_addr),
        .ml_bram_dout(ml_bram_dout),
        .ml_bram_din(ml_bram_din), // <-- unused
        .ml_bram_wea(ml_bram_wea),
        .ml_bram_enable(ml_bram_enable),

        // VL BRAM stuff
        .vl_bram_addr(vl_bram_addr),
        .vl_bram_dout(vl_bram_dout),
        .vl_bram_din(vl_bram_din), // <-- unused
        .vl_bram_wea(vl_bram_wea),
        .vl_bram_enable(vl_bram_enable),

        // VAU0 BRAM stuff
        .vau0_bram_addr(vau0_bram_addr),
        .vau0_bram_dout(vau0_bram_dout),
        .vau0_bram_din(vau0_bram_din),
        .vau0_bram_wea(vau0_bram_wea),
        .vau0_bram_enable(vau0_bram_enable),

        // VAU1 BRAM stuff
        .vau1_bram_addr(vau1_bram_addr),
        .vau1_bram_dout(vau1_bram_dout),
        .vau1_bram_din(vau1_bram_din),
        .vau1_bram_wea(vau1_bram_wea),
        .vau1_bram_enable(vau1_bram_enable),

        // ----------THESE SHOULD BE TWO PORTS ON THE SAME BRAM------------
        // PE0-Send BRAM stuff
        .pe0s_bram_addr(pe0s_bram_addr),
        .pe0s_bram_dout(pe0s_bram_dout),
        .pe0s_bram_din(pe0s_bram_din),
        .pe0s_bram_wea(pe0s_bram_wea),
        .pe0s_bram_enable(pe0s_bram_enable),
        // PE0-Recv BRAM stuff
        .pe0a_bram_addr(pe0a_bram_addr),
        .pe0a_bram_dout(pe0a_bram_dout), // <-- unused
        .pe0a_bram_din(pe0a_bram_din),
        .pe0a_bram_wea(pe0a_bram_wea),
        .pe0a_bram_enable(pe0a_bram_enable),
        // ----------------------------------------------------------------

        // ----------THESE SHOULD BE TWO PORTS ON THE SAME BRAM------------
        // PE1-Send BRAM stuff
        .pe1s_bram_addr(pe1s_bram_addr),
        .pe1s_bram_dout(pe1s_bram_dout),
        .pe1s_bram_din(pe1s_bram_din),
        .pe1s_bram_wea(pe1s_bram_wea),
        .pe1s_bram_enable(pe1s_bram_enable),
        // PE1-Recv BRAM stuff
        .pe1a_bram_addr(pe1a_bram_addr),
        .pe1a_bram_dout(pe1a_bram_dout), // <-- unused
        .pe1a_bram_din(pe1a_bram_din),
        .pe1a_bram_wea(pe1a_bram_wea),
        .pe1a_bram_enable(pe1a_bram_enable)
        // ----------------------------------------------------------------
    );

endmodule
`default_nettype wire
