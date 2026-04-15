// drives the 4 partition 2 stream example
// bram_info_pipeline will wrap the memory requests, this will handle the rest
module single_cluster_opt_driver(
    input wire clk,
    input wire reset,

    output logic finished,
    output logic [31:0] num_cycles,
    output logic [7:0] [31:0] final_vec,

    // ML-send inputs/outputs
    output logic [31:0] t__cur_row_partition,
    output logic t__cur_row_partition_vld,
    output logic [31:0] t__num_col_partitions,
    output logic t__num_col_partitions_vld,
    output logic [31:0] t__tot_num_partitions,
    output logic t__tot_num_partitions_vld,
    // output logic t__unified_addr_rdy,

    // input logic [63:0] t__unified_addr,
    // input logic t__unified_addr_vld,
    input logic t__cur_row_partition_rdy,
    input logic t__num_col_partitions_rdy,
    input logic t__tot_num_partitions_rdy,

    // ML-recv inputs/outputs
    // output logic [159:0] t__unified_pld,
    // output logic t__unified_pld_vld,
    // input logic t__unified_pld_rdy,

    // VL inputs/outputs
    // output logic t__hbm_vector_addr_rdy,
    // output logic [63:0] t__hbm_vector_payload,
    // output logic t__hbm_vector_payload_vld,
    output logic [31:0] t__num_matrix_cols,
    output logic t__num_matrix_cols_vld,
    // input logic [31:0] t__hbm_vector_addr,
    // input logic t__hbm_vector_addr_vld,
    // input logic t__hbm_vector_payload_rdy,
    input logic t__num_matrix_cols_rdy,

    // VAU 0 inputs/outputs
    output logic [31:0] vecbuf0_t__num_col_partitions,
    output logic vecbuf0_t__num_col_partitions_vld,
    // output logic vecbuf0_t__unified_addr_rdy,
    // output logic [95:0] vecbuf0_t__streaming_pld,
    // output logic vecbuf0_t__streaming_pld_vld,
    input logic vecbuf0_t__num_col_partitions_rdy,
    // input logic [127:0] vecbuf0_t__unified_addr,
    // input logic vecbuf0_t__unified_addr_vld,
    // input logic vecbuf0_t__streaming_pld_rdy,

    // VAU 1 inputs/outputs
    output logic [31:0] vecbuf1_t__num_col_partitions,
    output logic vecbuf1_t__num_col_partitions_vld,
    // output logic vecbuf1_t__unified_addr_rdy,
    // output logic [95:0] vecbuf1_t__streaming_pld,
    // output logic vecbuf1_t__streaming_pld_vld,
    input logic vecbuf1_t__num_col_partitions_rdy,
    // input logic [127:0] vecbuf1_t__unified_addr,
    // input logic vecbuf1_t__unified_addr_vld,
    // input logic vecbuf1_t__streaming_pld_rdy,

    // PE0_send inputs/outputs
    output logic [29:0] pe0_t__num_rows_updated,
    output logic pe0_t__num_rows_updated_vld,
    input logic pe0_t__num_rows_updated_rdy,
    // PE0_arbiter inputs/outputs
    // output logic pe0_t__unified_addr_rdy,
    // input logic [127:0] pe0_t__unified_addr,
    // input logic pe0_t__unified_addr_vld,
    // PE0_recv inputs/oututs
    output logic [31:0] pe0_t__stream_id,
    output logic pe0_t__stream_id_vld,
    // output logic [127:0] pe0_t__unified_pld,
    // output logic pe0_t__unified_pld_vld,
    // output logic pe0_t__accumulation_addr_rdy,
    // output logic [127:0] pe0_t__dummy_accumulate_pld,
    // output logic pe0_t__dummy_accumulate_pld_vld,
    input logic pe0_t__stream_id_rdy,
    // input logic pe0_t__unified_pld_rdy,
    // input logic [127:0] pe0_t__accumulation_addr,
    // input logic pe0_t__accumulation_addr_vld,

    // PE1_send inputs/outputs
    output logic [29:0] pe1_t__num_rows_updated,
    output logic pe1_t__num_rows_updated_vld,
    input logic pe1_t__num_rows_updated_rdy,
    // PE1_arbiter inputs/outputs
    // output logic pe1_t__unified_addr_rdy,
    // input logic [127:0] pe1_t__unified_addr,
    // input logic pe1_t__unified_addr_vld,
    // PE1_recv inputs/oututs
    output logic [31:0] pe1_t__stream_id,
    output logic pe1_t__stream_id_vld,
    // output logic [127:0] pe1_t__unified_pld,
    // output logic pe1_t__unified_pld_vld,
    // output logic pe1_t__accumulation_addr_rdy,
    // output logic [127:0] pe1_t__dummy_accumulate_pld,
    // output logic pe1_t__dummy_accumulate_pld_vld,
    input logic pe1_t__stream_id_rdy,
    // input logic pe1_t__unified_pld_rdy,
    // input logic [127:0] pe1_t__accumulation_addr,
    // input logic pe1_t__accumulation_addr_vld,

    // kmerger inputs/outputs
    output logic [31:0] kmerger_t__current_row_partition,
    output logic kmerger_t__current_row_partition_vld,
    output logic kmerger_t__hbm_vector_addr_rdy,
    output logic kmerger_t__hbm_vector_payload_rdy,
    output logic [31:0] kmerger_t__num_hbm_channels_each_kernel,
    output logic kmerger_t__num_hbm_channels_each_kernel_vld,
    input logic kmerger_t__current_row_partition_rdy,
    input logic [31:0] kmerger_t__hbm_vector_addr,
    input logic kmerger_t__hbm_vector_addr_vld,
    input logic [63:0] kmerger_t__hbm_vector_payload,
    input logic kmerger_t__hbm_vector_payload_vld,
    input logic kmerger_t__num_hbm_channels_each_kernel_rdy
);

    localparam row_parts = 2;

    enum {IDLE, DRIVE_ONE, DRIVE_TWO, RES_WAIT, FINISH} state;
    logic drive_one_sent, drive_two_sent;
    logic [31:0] cur_row_part, cur_res_read; // <-- left off here, cur_res_read is the loop for reading the results

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            kmerger_t__hbm_vector_addr_rdy <= 0;
            kmerger_t__hbm_vector_payload_rdy <= 0;
            cur_row_part <= 1;
            drive_one_sent <= 0;
            num_cycles <= 0;
            finished <= 0;
        end
        else begin
            kmerger_t__hbm_vector_addr_rdy <= (kmerger_t__hbm_vector_addr_vld && kmerger_t__hbm_vector_payload_vld);
            kmerger_t__hbm_vector_payload_rdy <= (kmerger_t__hbm_vector_addr_vld && kmerger_t__hbm_vector_payload_vld);
            if (state != FINISH) begin
                num_cycles <= num_cycles + 1;
            end
            case(state)
                IDLE: begin
                    state <= DRIVE_ONE;
                end
                DRIVE_ONE: begin
                    if (!drive_one_sent) begin
                        t__cur_row_partition <= cur_row_part;
                        t__cur_row_partition_vld <= 1;
                        t__num_col_partitions <= 2;
                        t__num_col_partitions_vld <= 1;
                        t__tot_num_partitions <= 4;
                        t__tot_num_partitions_vld <= 1;
                        t__num_matrix_cols <= 8;
                        t__num_matrix_cols_vld <= 1;
                        kmerger_t__current_row_partition <= cur_row_part;
                        kmerger_t__current_row_partition_vld <= 1;
                        kmerger_t__num_hbm_channels_each_kernel <= 1;
                        kmerger_t__num_hbm_channels_each_kernel_vld <= 1;
                        drive_one_sent <= 1;
                    end
                    if (drive_one_sent) begin
                        if (t__cur_row_partition_rdy && t__num_col_partitions_rdy && t__tot_num_partitions_rdy && t__num_matrix_cols_rdy && kmerger_t__current_row_partition_rdy && kmerger_t__num_hbm_channels_each_kernel_rdy) begin
                            t__cur_row_partition_vld <= 0;
                            t__num_col_partitions_vld <= 0;
                            t__tot_num_partitions_vld <= 0;
                            t__num_matrix_cols_vld <= 0;
                            kmerger_t__current_row_partition_vld <= 0;
                            kmerger_t__num_hbm_channels_each_kernel_vld <= 0;
                            state <= DRIVE_TWO;
                            drive_one_sent <= 0;
                            drive_two_sent <= 0;
                        end
                    end
                end
                DRIVE_TWO: begin
                    if (!drive_two_sent) begin
                        vecbuf0_t__num_col_partitions <= 2;
                        vecbuf0_t__num_col_partitions_vld <= 1;
                        vecbuf1_t__num_col_partitions <= 2;
                        vecbuf1_t__num_col_partitions_vld <= 1;
                        pe0_t__num_rows_updated <= 2;
                        pe0_t__num_rows_updated_vld <= 1;
                        pe0_t__stream_id <= 0;
                        pe0_t__stream_id_vld <= 1;
                        pe1_t__num_rows_updated <= 2;
                        pe1_t__num_rows_updated_vld <= 1;
                        pe1_t__stream_id <= 1;
                        pe1_t__stream_id_vld <= 1;
                        drive_two_sent <= 1;
                    end
                    if (drive_two_sent) begin
                        if (vecbuf0_t__num_col_partitions_rdy && vecbuf1_t__num_col_partitions_rdy && pe0_t__num_rows_updated_rdy && pe0_t__stream_id_rdy && pe1_t__num_rows_updated_rdy && pe1_t__stream_id_rdy) begin
                            vecbuf0_t__num_col_partitions_vld <= 0;
                            vecbuf1_t__num_col_partitions_vld <= 0;
                            pe0_t__num_rows_updated_vld <= 0;
                            pe0_t__stream_id_vld <= 0;
                            pe1_t__num_rows_updated_vld <= 0;
                            pe1_t__stream_id_vld <= 0;
                            state <= RES_WAIT;
                            drive_two_sent <= 0;
                            cur_res_read <= 0;
                        end
                    end
                end
                RES_WAIT: begin
                    if (kmerger_t__hbm_vector_addr_vld && kmerger_t__hbm_vector_payload_vld) begin
                        final_vec[(kmerger_t__hbm_vector_addr >> 1)] <= kmerger_t__hbm_vector_payload[63:32];
                        final_vec[(kmerger_t__hbm_vector_addr >> 1) + 1] <= kmerger_t__hbm_vector_payload[31:0];
                        cur_res_read <= cur_res_read + 1;
                        if (cur_res_read == 1) begin
                            cur_row_part <= 1;
                            if (cur_row_part == (row_parts - 1)) begin
                                state <= FINISH;
                                finished <= 1;
                            end
                            else begin
                                state <= DRIVE_ONE;
                            end
                        end
                    end
                end
                FINISH: begin
                    // do nothing
                end
                default: begin
                end
            endcase
        end
    end    
endmodule
