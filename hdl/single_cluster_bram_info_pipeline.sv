`default_nettype none
// read latency must not be 1
module single_cluster_bram_info_pipeline
    #(
        parameter INFO_WIDTH=32,
        parameter DOUT_WIDTH=32,
        parameter READ_LATENCY=2
    )
    (
        input wire clk,
        input wire reset,

        input wire [INFO_WIDTH-1:0] info,
        input wire info_vld,
        input wire [DOUT_WIDTH-1:0] dout,
        input wire downstream_ready,
        output wire upstream_ready,
        
        output wire [INFO_WIDTH-1:0] p_info,
        output logic [DOUT_WIDTH-1:0] p_dout,
        output wire p_vld
    );

    logic [READ_LATENCY:0] vld_pp;
    logic [READ_LATENCY:0] [INFO_WIDTH-1:0] info_pp;

    assign p_info = info_pp[0];
    assign p_vld = vld_pp[0];
    logic stall_cond;
    assign stall_cond = (vld_pp[0] && !downstream_ready);
    assign upstream_ready = !stall_cond;
    always_ff @(posedge clk) begin
        if (reset) begin
            vld_pp <= '0;
            info_pp <= '0;
        end
        else begin
            if (upstream_ready) begin
                vld_pp <= {info_vld, vld_pp[READ_LATENCY:1]};
                info_pp <= {info, info_pp[READ_LATENCY:1]};
            end
        end
    end

    logic old_ready;
    logic [READ_LATENCY-1:0] [DOUT_WIDTH-1:0] skid_pp;
    logic [31:0] skid_count;
    logic [DOUT_WIDTH-1:0] old_dout;
    always_ff @(posedge clk) begin
        if (reset) begin
            skid_count <= 0;
            old_ready <= 0;
        end
        else begin
            old_ready <= upstream_ready;
            old_dout <= dout;
            if (skid_count == 0 && upstream_ready) begin // no skid
                p_dout <= dout;
            end
            else if (skid_count > 0 && upstream_ready) begin // dump skid
                skid_count <= skid_count - 1;
                if (old_dout != dout) begin
                    // non blocking assing priority assign stopping skid from decreasing since
                    // this skid kick out was replaced with the incoming dout
                    // also add new dout into skid
                    skid_pp <= {dout, skid_pp[READ_LATENCY-1:1]};
                    skid_count <= skid_count;
                end
                p_dout <= skid_pp[READ_LATENCY - skid_count]; // because we load from MSB, this is how we read
            end
            else if (!upstream_ready && skid_count < READ_LATENCY) begin // load skid
                skid_pp <= {dout, skid_pp[READ_LATENCY-1:1]};
                skid_count <= skid_count + 1;
            end
        end
    end
endmodule
`default_nettype wire
