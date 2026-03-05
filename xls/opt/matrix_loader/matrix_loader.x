import matrix_init_state;
import matrix_helper;

pub proc matrix_loader<NUM_STREAMS: u32>
{
    // matrix loader sends index out, receives payload in

    // in "scheduling constraints" of https://google.github.io/xls/tutorials/how_to_use_procs/,
    // it mentions how to use io_constraints to tie in external constraints.
    // In our case, if we have the external memory modeled (say BRAM that takes 2 cycles), we 
    // should be able to say (potentially using filament style syntax) to read from payload_type_one
    // after waiting N cycles
    payload_type_one:                       chan<uN[64][NUM_STREAMS]> in;   // single channel pulling from the HBM
    payload_type_one_index:                 chan<u32> out; // the scheduling constraint for this addr/index to external ram can be configured via "scheduling constraints" here https://google.github.io/xls/tutorials/how_to_use_procs/
    cur_row_partition:                      chan<u32> in;
    num_col_partitions:                     chan<u32> in; // constant
    tot_num_partitions:                     chan<u32> in; // constant
    multistream_payload_type_two:           chan<uN[96]>[NUM_STREAMS] out;  // multiple channels, a channel per stream, for the output

    config(
        payload_type_one:                   chan<uN[64][NUM_STREAMS]> in,
        payload_type_one_index:             chan<u32> out,
        cur_row_partition:                  chan<u32> in,
        num_col_partitions:                 chan<u32> in,  // constant
        tot_num_partitions:                 chan<u32> in,  // constant
        multistream_payload_type_two:       chan<uN[96]>[NUM_STREAMS] out
    ) {
        (
            payload_type_one,
            payload_type_one_index,
            cur_row_partition,
            num_col_partitions,
            tot_num_partitions,
            multistream_payload_type_two
        )
    }

    init {(
        u32: 0,                    // 0 our literal state (all state reset)
        
        // state variables
        zero!<u32[NUM_STREAMS]>(), // 1 per stream row idx (state 1 reset)
        u32: 0,                    // 2 row partition idx (state 0 reset)                                            
        u32: 0,                    // 3 num col partitions (state 0 reset)
        u32: 0,                    // 4 num partitions (state 0 reset)
        u32: 0,                    // 5 current col partition (state 0 reset)
        u32: 0,                    // 6 start indx of partition (state 1 reset)
        zero!<u32[NUM_STREAMS]>(), // 7 stream lengths of partition (state 1 reset)
        u32: 0,                    // 8 max length of partition/num_reads (state 1 reset)
        u32: 0,                    // 9 current read (state 1 reset)

        // state has a token to ensure successive
        // activations are ordered correctly
        // (see cross activation tokens here:
        // https://google.github.io/xls/tutorials/what_is_a_proc/)
        join(),                    // 10 token ordering activations (all state reset)

        // substate state
        u32: 0,                         // substate counter
        zero!<uN[96][NUM_STREAMS]>(),   // substate multistream payload
        false                            // finished row predicate


    )}

    // !!! anything that isnt either updated or reset by a given state must be passed through by said state !!!
    next (state: (u32, u32[NUM_STREAMS], u32, u32, u32, u32, u32, u32[NUM_STREAMS], u32, u32, token, u32, uN[96][NUM_STREAMS], bool)) {

        // state print for debugging
        // trace_fmt!(" ");
        // trace_fmt!(" current state ");
        // trace_fmt!("---------------");
        // trace_fmt!("state: {:0x}", state.0);
        // trace_fmt!("row i: {:0x}", state.1);
        // trace_fmt!("rowpi: {:0x}", state.2);
        // trace_fmt!("# col: {:0x}", state.3);
        // trace_fmt!("# prt: {:0x}", state.4);
        // trace_fmt!("cur c: {:0x}", state.5);
        // trace_fmt!("start: {:0x}", state.6);
        // trace_fmt!("slens: {:0x}", state.7);
        // trace_fmt!("max l: {:0x}", state.8);
        // trace_fmt!("cread: {:0x}", state.9);
        // // substate prints
        // trace_fmt!("subcount: {:0x}", state.11);
        // trace_fmt!("subpld: {:0x}", state.12);
        // trace_fmt!("rowpred: {:0x}", state.13);
        // trace_fmt!("---------------");
        // trace_fmt!(" ");
        // trace_fmt!(" ");

        // 1) Calculation of TX/RX boolean variables
        // note we either are only receiving, or only sending. Not both
        let
        (
            ptoi_tx, mptt_tx,
            pto_rx, crp_rx, ncp_rx, tnp_rx   
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
            u32: 20 => {
                (
                    true, false,
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
                    false, state.13,
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

        // 2) calculation of send payloads
        let 
        (
            ptoi_pld, mptt_pld
        ) = 
        match (state.0) {
            u32: 10 => {
                let part_id = state.2 * state.3 + state.5;
                let part_meta_idx = part_id * 2;
                let part_meta_idx = if (state.11 == u32: 0) { part_meta_idx } else { part_meta_idx + u32: 1 };
                (
                    part_meta_idx, zero!<uN[96][NUM_STREAMS]>()
                )
            },
            u32: 12 => {
                let mptt_pld =
                for (idx, pld) : (u32, uN[96][NUM_STREAMS]) in u32:0..NUM_STREAMS {
                    let n_pld = update(pld, idx, matrix_helper::payload_converter<NUM_STREAMS>(zero!<uN[64]>(), u32: 0, u2: 1));
                    (n_pld)
                }(zero!<uN[96][NUM_STREAMS]>());
                (
                    u32: 0, mptt_pld
                )
            },
            u32: 20 => {
                let metadata_offset = state.4 * 2;
                let payload_idx = metadata_offset + state.6 + state.9;
                (
                    payload_idx, zero!<uN[96][NUM_STREAMS]>()
                )
            },
            u32: 22 => {
                (
                    u32: 0, state.12
                )
            },
            u32: 30 => {
                let mptt_pld =
                for (idx, pld) : (u32, uN[96][NUM_STREAMS]) in u32:0..NUM_STREAMS {
                    let n_pld = update(pld, idx, matrix_helper::payload_converter<NUM_STREAMS>(zero!<uN[64]>(), u32: 0, u2: 2));
                    (n_pld)
                }(zero!<uN[96][NUM_STREAMS]>());
                (
                    u32: 0, mptt_pld
                )
            },
            u32: 31 => {
                let mptt_pld =
                for (idx, pld) : (u32, uN[96][NUM_STREAMS]) in u32:0..NUM_STREAMS {
                    let n_pld = update(pld, idx, matrix_helper::payload_converter<NUM_STREAMS>(zero!<uN[64]>(), u32: 0, u2: 3));
                    (n_pld)
                }(zero!<uN[96][NUM_STREAMS]>());
                (
                    u32: 0, mptt_pld
                )
            },
            _ => {
                (
                    u32: 0, zero!<uN[96][NUM_STREAMS]>()
                )
            }         
        };

        // 3) Sends and Receives, Receives latched into payloads. 
        // All channels triggered at (mostly) the same time
        // (mostly because unroll_for! semantics limit me)
        // sends
        let t1 = send_if(state.10, payload_type_one_index, ptoi_tx, ptoi_pld);
        let t2 = 
        unroll_for! (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
            let n_tok = send_if(tok, multistream_payload_type_two[idx], mptt_tx, mptt_pld[idx]);
            (n_tok)
        }(state.10);
        // receives
        let (t3, pto_pld) = recv_if(state.10, payload_type_one, pto_rx, zero!<uN[64][NUM_STREAMS]>());
        let (t4, crp_pld) = recv_if(state.10, cur_row_partition, crp_rx, u32: 0);
        let (t5, ncp_pld) = recv_if(state.10, num_col_partitions, ncp_rx, u32: 0);
        let (t6, tnp_pld) = recv_if(state.10, tot_num_partitions, tnp_rx, u32: 0);
        // join
        let new_tok = join(t1, t2, t3, t4, t5, t6);

        // 4) state updates
        let 
        (
            st0, st1, st2, st3, st4, st5, st6, st7, st8, st9, st11, st12, st13 // note we skip st10 because thats a token 
                                                                         // and match arms cant flow tokens
        ) =
        match (state.0) {
            u32: 0 => {
                let new_current_col_part = u32: 0;
                let new_state = u32: 10;
                let new_state_counter = u32: 0;
                (
                    new_state, state.1, crp_pld, ncp_pld,
                    tnp_pld, new_current_col_part, state.6, state.7,
                    state.8, state.9, new_state_counter, state.12, state.13
                )
            },
            u32: 10 => {
                let new_state = u32: 11;
                let new_state_counter = state.11 + u32: 1;
                (
                    new_state, state.1, state.2, state.3, state.4, state.5, 
                    state.6, state.7, state.8, state.9, new_state_counter, state.12, state.13
                )
            },
            u32: 11 => {
                let (
                    new_state, new_row_array, new_start_of_partition, new_stream_lengths_of_partition, new_max, new_read, new_state_counter
                ) =
                if (state.11 == u32: 1) {
                    let (new_start_of_partition, _) = matrix_helper::unpack_payload_one<NUM_STREAMS>(pto_pld, u32: 0);
                    let new_state_counter = state.11 + u32: 1;
                    let new_state = u32: 10;
                    (
                        new_state, state.1, new_start_of_partition, state.7, state.8, state.9, new_state_counter
                    )
                }
                else {
                    let new_stream_lengths_of_partition =
                    for (idx, lengths) : (u32, u32[NUM_STREAMS]) in u32:0..NUM_STREAMS {
                        let (length, _) = matrix_helper::unpack_payload_one<NUM_STREAMS>(pto_pld, idx);
                        let new_lengths = update(lengths, idx, length);
                        (new_lengths)
                    }((zero!<u32[NUM_STREAMS]>()));
                    let new_max = matrix_helper::max_array<NUM_STREAMS>(new_stream_lengths_of_partition);            
                    let new_row_array = matrix_init_state::matrix_loader_initial_state<NUM_STREAMS>();
                    let new_read = u32: 0;
                    let new_state_counter = u32: 0;
                    let new_state = u32: 12;
                    (
                        new_state, new_row_array, state.6, new_stream_lengths_of_partition, new_max, new_read, new_state_counter
                    )
                };
                (
                    new_state, new_row_array, state.2, state.3, state.4,
                    state.5, new_start_of_partition, new_stream_lengths_of_partition,
                    new_max, new_read, new_state_counter, state.12, state.13
                )
            },
            u32: 12 => {
                let new_state = u32: 20;
                (
                    new_state, state.1, state.2, state.3, state.4, state.5, 
                    state.6, state.7, state.8, state.9, state.11, state.12, state.13
                )
            },
            u32: 20 => {
                let new_state = u32: 21;
                (
                    new_state, state.1, state.2, state.3, state.4, state.5, 
                    state.6, state.7, state.8, state.9, state.11, state.12, state.13
                )
            },
            u32: 21 => {
                let new_state = u32: 22;
                let (new_row_array, new_payload) = 
                for (idx, (array, payload)) : (u32, (u32[NUM_STREAMS], uN[96][NUM_STREAMS])) in u32:0..NUM_STREAMS {
                    let (index, _) = matrix_helper::unpack_payload_one<NUM_STREAMS>(pto_pld, idx);
                    let next_row_marker_predicate = index == all_ones!<u32>();
                    // too lazy to rewrite this, yes the stream_payload_two is unecessary
                    let stream_payload_two = matrix_helper::payload_converter<NUM_STREAMS>(pto_pld[idx], state.1[idx], u2: 0);
                    let outgoing_payload_two = if (next_row_marker_predicate) { zero!<uN[96]>() } else { stream_payload_two };
                    let new_payload = update(payload, idx, outgoing_payload_two);
                    let new_array = if (next_row_marker_predicate) { update(array, idx, stream_payload_two[32+: u32]) } else { array };
                    (new_array, new_payload)
                }((state.1, zero!<uN[96][NUM_STREAMS]>()));
                (
                    new_state, new_row_array, state.2, state.3, state.4, state.5, 
                    state.6, state.7, state.8, state.9, state.11, new_payload, state.13
                )
            },
            u32: 22 => {
                let new_read = state.9 + u32: 1;
                let new_state = if (new_read >= state.8) { u32: 30 } else { u32: 20 };
                (
                    new_state, state.1, state.2, state.3, state.4, state.5, 
                    state.6, state.7, state.8, new_read, state.11, state.12, state.13
                )
            },
            u32: 30 => {
                let new_state = u32: 31;
                let new_current_col_part = state.5 + u32: 1;
                let new_pred = new_current_col_part >= state.3;
                (
                    new_state, state.1, state.2, state.3, state.4, new_current_col_part, 
                    state.6, state.7, state.8, state.9, state.11, state.12, new_pred
                )
            },
            u32: 31 => {
                let new_state = if (state.13) { u32: 0 } else { u32: 10 };
                (
                    new_state, state.1, state.2, state.3, state.4, state.5, 
                    state.6, state.7, state.8, state.9, state.11, state.12, state.13
                )
            },
            _ => {
                (
                    state.0, state.1, state.2, state.3, state.4, state.5, 
                    state.6, state.7, state.8, state.9, state.11, state.12, state.13
                )
            }
        };

        (
            st0, st1, st2, st3, st4, st5, st6, st7, st8, st9, new_tok, st11, st12, st13
        )

    }

}