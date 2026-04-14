// read latency must not be 1
module single_cluster_bram_info_pipeline
    #(
        parameter INFO_WIDTH=32,
        parameter READ_LATENCY=2
    )
    (
        input wire clk,
        input wire reset,

        input wire [INFO_WIDTH-1:0] info,
        input wire info_vld,
        input wire downstream_ready,
        output wire upstream_ready,
        
        output wire [INFO_WIDTH-1:0] p_info,
        output wire p_vld
    );

    logic [READ_LATENCY-1:0] vld_pp;
    logic [READ_LATENCY-1:0] [INFO_WIDTH-1:0] info_pp;

    assign p_info = info_pp[0];
    assign p_vld = vld_pp[0];
    logic stall_cond;
    assign stall_cond = (vld_pp[0] && !downstream_ready)
    assign upstream_ready = !stall_cond;
    always_ff @(posedge clk) begin
        if (reset) begin
            vld_pp <= '0;
            info_pp <= '0;
        end
        else begin
            if (upstream_ready) {
                vld_pp <= {info_vld, vld_pp[READ_LATENCY-1:1]};
                info_pp <= {info, info_pp[READ_LATENCY-1:1]};
            }
        end
    end
endmodule