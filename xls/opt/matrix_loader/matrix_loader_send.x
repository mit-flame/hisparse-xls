import matrix_init_state;
import matrix_helper;

pub proc matrix_loader_send<NUM_STREAMS: u32>
{
    metadata_addr:                          chan<u32> out;
    metadata_payload:                       chan<uN[64][NUM_STREAMS]> in;
    streaming_addr:                         chan<matrix_helper::StreamAddr> out;
    cur_row_partition:                      chan<u32> in;
    num_col_partitions:                     chan<u32> in; // constant
    tot_num_partitions:                     chan<u32> in; // constant

    config(
        metadata_addr:                      chan<u32> out,
        metadata_payload:                   chan<uN[64][NUM_STREAMS]> in,
        streaming_addr:                     chan<matrix_helper::StreamAddr> out,
        cur_row_partition:                  chan<u32> in,
        num_col_partitions:                 chan<u32> in,  // constant
        tot_num_partitions:                 chan<u32> in  // constant
    ) {
        (
            metadata_addr,
            metadata_payload,
            streaming_addr,
            cur_row_partition,
            num_col_partitions,
            tot_num_partitions
        )
    }

    init {(
        u32: 0,                    // 0 our literal state (all state reset)        
        u32: 0,                    // 1 row partition idx (state 0 reset)                                            
        u32: 0,                    // 2 num col partitions (state 0 reset)
        u32: 0,                    // 3 num partitions (state 0 reset)
        u32: 0,                    // 4 current col partition (state 0 reset)
        u32: 0,                    // 5 start indx of partition (state 1 reset)
        zero!<u32[NUM_STREAMS]>(), // 6 stream lengths of partition (state 1 reset)
        u32: 0,                    // 7 max length of partition/num_reads (state 1 reset)
        u32: 0,                    // 8 current read (state 1 reset)
        join(),                    // 9 token ordering activations (all state reset)

        // substate state
        u32: 0,                         // substate counter
        false                           // finished row predicate
    )}

    // !!! anything that isnt either updated or reset by a given state must be passed through by said state !!!
    next (state: (u32, u32, u32, u32, u32, u32, u32[NUM_STREAMS], u32, u32, token, u32, bool)) {

        // trace_fmt!("num col p {:0x} cur col p {:0x}", state.2, state.4);
        // trace_fmt!("state {:0x}", state.0);

        let
        (
            ma_tx, sa_tx,
            mp_rx, crp_rx, ncp_rx, tnp_rx   
        ) =
        match (state.0) {
            u32: 0 => {
                (
                    false, false,
                    false, true, true, true
                )
            },
            u32: 10 => { // state reads as "1.0" or state 1 substate 0
                (
                    true, false,
                    false, false, false, false
                )
            },
            u32: 11 => {
                (
                    false, false,
                    true, false, false, false
                )
            },
            u32: 12 => {
                (
                    false, true,
                    false, false, false, false
                )
            },
            u32: 2 => {
                (
                    false, true,
                    false, false, false, false
                )
            },
            u32: 21 => {
                (
                    false, false,
                    true, false, false, false
                )
            },
            u32: 22 => {
                (
                    false, true,
                    false, false, false, false
                )
            },
            u32: 30 => {
                (
                    false, true,
                    false, false, false, false
                )
            },
            u32: 31 => {
                (
                    false, state.11,
                    false, false, false, false
                )
            },
            _ => {
                (
                    false, false,
                    false, false, false, false
                )
            }
        };

        let 
        (
            ma_pld, sa_pld
        ) = 
        match (state.0) {
            u32: 10 => {
                let part_id = state.1 * state.2 + state.4;
                let part_meta_idx = part_id * 2;
                let part_meta_idx = if (state.10 == u32: 0) { part_meta_idx } else { part_meta_idx + u32: 1 };
                (
                    part_meta_idx, zero!<matrix_helper::StreamAddr>()
                )
            },
            u32: 12 => {
                let sa_pld = matrix_helper::StreamAddr{addr: u32: 0, commands: u2: 1 ++ u30: 0};
                (
                    u32: 0, sa_pld
                )
            },
            u32: 2 => {
                let metadata_offset = state.3 * 2;
                let payload_idx = metadata_offset + state.5 + state.8;
                let sa_pld = matrix_helper::StreamAddr{addr: payload_idx, commands: u32: 0};
                (
                    u32: 0, sa_pld
                )
            },
            u32: 30 => {
                let sa_pld = matrix_helper::StreamAddr{addr: u32: 0, commands: u2: 2 ++ u30: 0};
                (
                    u32: 0, sa_pld
                )
            },
            u32: 31 => {
                let sa_pld = matrix_helper::StreamAddr{addr: u32: 0, commands: u2: 3 ++ u30: 0};
                (
                    u32: 0, sa_pld
                )
            },
            _ => {
                (
                    u32: 0, zero!<matrix_helper::StreamAddr>()
                )
            }         
        };

        let t1 = send_if(state.9, metadata_addr, ma_tx, ma_pld);
        let t2 = send_if(state.9, streaming_addr, sa_tx, sa_pld);
        let (t3, mp_pld) = recv_if(state.9, metadata_payload, mp_rx, zero!<uN[64][NUM_STREAMS]>());
        let (t4, crp_pld) = recv_if(state.9, cur_row_partition, crp_rx, u32: 0);
        let (t5, ncp_pld) = recv_if(state.9, num_col_partitions, ncp_rx, u32: 0);
        let (t6, tnp_pld) = recv_if(state.9, tot_num_partitions, tnp_rx, u32: 0);
        let new_tok = join(t1, t2, t3, t4, t5, t6);

        let 
        (
            st0, st1, st2, st3, st4, st5, st6, st7, st8, st10, st11
        ) =
        match (state.0) {
            u32: 0 => {
                let new_current_col_part = u32: 0;
                let new_state = u32: 10;
                let new_state_counter = u32: 0;
                (
                    new_state, crp_pld, ncp_pld, tnp_pld,
                    new_current_col_part, state.5, state.6,
                    state.7, state.8, new_state_counter, state.11
                )
            },
            u32: 10 => {
                let new_state = u32: 11;
                let new_state_counter = state.10 + u32: 1;
                (
                    new_state, state.1, state.2, state.3, state.4, 
                    state.5, state.6, state.7, state.8, new_state_counter, state.11
                )
            },
            u32: 11 => {
                let (
                    new_state, new_start_of_partition, new_stream_lengths_of_partition, new_max, new_read, new_state_counter
                ) =
                if (state.10 == u32: 1) {
                    let (new_start_of_partition, _) = matrix_helper::unpack_payload_one<NUM_STREAMS>(mp_pld, u32: 0);
                    let new_state_counter = state.10 + u32: 1;
                    let new_state = u32: 10;
                    (
                        new_state, new_start_of_partition, state.6, state.7, state.8, new_state_counter
                    )
                }
                else {
                    let new_stream_lengths_of_partition =
                    for (idx, lengths) : (u32, u32[NUM_STREAMS]) in u32:0..NUM_STREAMS {
                        let (length, _) = matrix_helper::unpack_payload_one<NUM_STREAMS>(mp_pld, idx);
                        let new_lengths = update(lengths, idx, length);
                        (new_lengths)
                    }((zero!<u32[NUM_STREAMS]>()));
                    let new_max = matrix_helper::max_array<NUM_STREAMS>(new_stream_lengths_of_partition);            
                    let new_read = u32: 0;
                    let new_state_counter = u32: 0;
                    let new_state = u32: 12;
                    (
                        new_state, state.5, new_stream_lengths_of_partition, new_max, new_read, new_state_counter
                    )
                };
                (
                    new_state, state.1, state.2, state.3,
                    state.4, new_start_of_partition, new_stream_lengths_of_partition,
                    new_max, new_read, new_state_counter, state.11
                )
            },
            u32: 12 => {
                let new_state = u32: 2;
                (
                    new_state, state.1, state.2, state.3, state.4, state.5,
                    state.6, state.7, state.8, state.10, state.11
                )
            },
            u32: 2 => {
                let new_read = state.8 + u32: 1;
                let new_state = if (new_read >= state.7) { u32: 30 } else { u32: 2 };
                (
                    new_state, state.1, state.2, state.3, state.4, state.5,
                    state.6, state.7, new_read, state.10, state.11
                )
            },
            u32: 30 => {
                let new_state = u32: 31;
                let new_current_col_part = state.4 + u32: 1;
                let new_pred = new_current_col_part >= state.2;
                (
                    new_state, state.1, state.2, state.3, new_current_col_part, 
                    state.5, state.6, state.7, state.8, state.10, new_pred
                )
            },
            u32: 31 => {
                let new_state = if (state.11) { u32: 0 } else { u32: 10 };
                (
                    new_state, state.1, state.2, state.3, state.4, state.5,
                    state.6, state.7, state.8, state.10, state.11
                )
            },
            _ => {
                (
                    state.0, state.1, state.2, state.3, state.4, state.5, 
                    state.6, state.7, state.8, state.10, state.11
                )
            }
        };

        (
            st0, st1, st2, st3, st4, st5, st6, st7, st8, new_tok, st10, st11
        )

    }

}