import matrix_init_state;
import matrix_helper;

pub proc matrix_loader<
    NUM_STREAMS: u32
>{
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
        join()                     // 10 token ordering activations (all state reset)
    )}

    // !!! anything that isnt either updated or reset by a given state must be passed through by said state !!!
    next (state: (u32, u32[NUM_STREAMS], u32, u32, u32, u32, u32, u32[NUM_STREAMS], u32, u32, token)) {

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
        // trace_fmt!("---------------");
        // trace_fmt!(" ");
        // trace_fmt!(" ");

        let new_state = 
        // a new row is being started. reset all state 0 items
        if (state.0 == u32: 0){
            let (rtok1, new_row_part_idx) = recv(state.10, cur_row_partition);
            let (rtok2, new_num_col_parts) = recv(state.10, num_col_partitions);
            let (rtok3, new_num_parts) = recv(state.10, tot_num_partitions);
            let new_tok = join(rtok1, rtok2, rtok3);
            let new_current_col_part = u32: 0;
            let new_state = u32: 1;
            (
                new_state, state.1, new_row_part_idx, new_num_col_parts,
                new_num_parts, new_current_col_part, state.6, state.7,
                state.8, state.9, new_tok
            )
        }
        else 
        // a new col partition is being started. reset all state 1 items. send SOD command
        // reset state 1 items
        if (state.0 == u32: 1){
            let part_id = state.2 * state.3 + state.5;
            let part_meta_idx = part_id * 2; // 2 packets per metadata, indicies are what convey metadata info
            let new_tok = send(state.10, payload_type_one_index, part_meta_idx);
            let (new_tok, meta_payload_one) = recv(new_tok, payload_type_one);
            let (new_start_of_partition, _) = matrix_helper::unpack_payload_one<NUM_STREAMS>(meta_payload_one, u32: 0);
            let new_tok = send(new_tok, payload_type_one_index, part_meta_idx + u32: 1);
            let (new_tok, meta_payload_two) = recv(new_tok, payload_type_one);
            let new_stream_lengths_of_partition =
            for (idx, lengths) : (u32, u32[NUM_STREAMS]) in u32:0..NUM_STREAMS {
                let (length, _) = matrix_helper::unpack_payload_one<NUM_STREAMS>(meta_payload_two, idx);
                let new_lengths = update(lengths, idx, length);
                (new_lengths)
            }((zero!<u32[NUM_STREAMS]>()));
            let new_max = matrix_helper::max_array<NUM_STREAMS>(new_stream_lengths_of_partition);            
            let new_row_array = matrix_init_state::matrix_loader_initial_state<NUM_STREAMS>();
            let new_read = u32: 0;

            // send SOD command
            let new_tok =
            for (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
                let n_tok = send(tok, multistream_payload_type_two[idx], matrix_helper::payload_converter<NUM_STREAMS>(zero!<uN[64]>(), u32: 0, u2: 1));
                (n_tok)
            }(new_tok);
            (
                u32: 2, new_row_array, state.2, state.3, state.4,
                state.5, new_start_of_partition, new_stream_lengths_of_partition,
                new_max, new_read, new_tok
            )
        }
        else 
        // stream conversion of payload type one. grab current read pointer payload,
        // make and send payload two, increment read pointer until hit max/num_reads
        if (state.0 == u32: 2){
            // stream conversion
            let metadata_offset = state.4 * 2;
            let payload_idx = metadata_offset + state.6 + state.9;
            let new_tok = send(state.10, payload_type_one_index, payload_idx);
            let (new_tok, payload_one) = recv(new_tok, payload_type_one);
            let (new_row_array, new_tok) =
            for (idx, (array, tok)) : (u32, (u32[NUM_STREAMS], token)) in u32:0..NUM_STREAMS {
                let (index, _) = matrix_helper::unpack_payload_one<NUM_STREAMS>(payload_one, idx);
                let next_row_marker_predicate = index == all_ones!<u32>();
                // next row markers and padding (which is also just a next row marker) will result in zeroed payload twos
                let stream_payload_two = matrix_helper::payload_converter<NUM_STREAMS>(payload_one[idx], state.1[idx], u2: 0);
                let outgoing_payload_two = if (next_row_marker_predicate) { zero!<uN[96]>() } else { stream_payload_two };
                let new_array = if (next_row_marker_predicate) { update(array, idx, stream_payload_two[32+: u32]) } else { array };
                let n_tok = send(tok, multistream_payload_type_two[idx], outgoing_payload_two);
                (new_array, n_tok)
            }((state.1, new_tok));
            let new_read = state.9 + u32: 1;

            // state calculation
            let new_state = if (new_read >= state.8) { u32: 3 } else { u32: 2 };
            (
                new_state, new_row_array, state.2, state.3, state.4,
                state.5, state.6, state.7, state.8, new_read, new_tok 
            )
        }
        else
        // finished col partition, figure out if there are more
        // send EOS if done with row
        if (state.0 == u32: 3) {
            // end of col partition cleanup
            let new_current_col_part = state.5 + u32: 1;
            let new_tok =
            for (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
                let n_tok = send(tok, multistream_payload_type_two[idx], matrix_helper::payload_converter<NUM_STREAMS>(zero!<uN[64]>(), u32: 0, u2: 2));
                (n_tok)
            }(state.10);

            // state calculation
            let finished_row_predicate = new_current_col_part >= state.3;
            let new_tok =
            for (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
                let n_tok = send_if(tok, multistream_payload_type_two[idx], finished_row_predicate, matrix_helper::payload_converter<NUM_STREAMS>(zero!<uN[64]>(), u32: 0, u2: 3));
                (n_tok)
            }(new_tok);
            let new_state = if (finished_row_predicate) { u32: 0 } else { u32: 1 };
            (
                new_state, state.1, state.2, state.3, state.4,
                new_current_col_part, state.6, state.7, state.8,
                state.9, new_tok
            )
        } else {
            // dummy state
            trace_fmt!("SHOULD NEVER BE IN THIS STATE!!!!!!!!!");
            (
                u32: 0, zero!<u32[NUM_STREAMS]>(), u32: 0, u32: 0, u32: 0, u32: 0,
                u32: 0, zero!<u32[NUM_STREAMS]>(), u32: 0, u32: 0, join()
            )
        };
        (new_state)
    }

}