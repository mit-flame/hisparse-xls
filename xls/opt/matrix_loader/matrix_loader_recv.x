import matrix_init_state;
import matrix_helper;

pub proc matrix_loader_recv<NUM_STREAMS: u32>
{
    streaming_payload_one:                  chan<matrix_helper::StreamPayload<NUM_STREAMS>> in;
    multistream_payload_type_two:           chan<uN[96]>[NUM_STREAMS] out;

    config(
        streaming_payload_one:                 chan<matrix_helper::StreamPayload<NUM_STREAMS>> in,
        multistream_payload_type_two:       chan<uN[96]>[NUM_STREAMS] out
    ) {
        (
            streaming_payload_one,
            multistream_payload_type_two
        )
    }

    init {(
        zero!<u32[NUM_STREAMS]>(), // 0 per stream row idx
        token()                    // 1 order token
    )}

    next (state: (u32[NUM_STREAMS], token)) {
        let (new_tok, spo_pld) = recv(state.1, streaming_payload_one);
        let payload_one = spo_pld.payload_type_one;
        let commands = spo_pld.commands;
        // SOD command will reset the row array
        let new_row_array = if (commands == u2: 1) { matrix_init_state::matrix_loader_initial_state<NUM_STREAMS>() } else { state.0 };
        
        let (new_row_array, new_tok) =
        unroll_for! (idx, (array, tok)) : (u32, (u32[NUM_STREAMS], token)) in u32:0..NUM_STREAMS {
            let (index, data) = matrix_helper::unpack_payload_one<NUM_STREAMS>(payload_one, idx);
            let next_row_marker_predicate = index == all_ones!<u32>();
            let pld_index = if (next_row_marker_predicate) { u30: 0 } else { (index as u30) };
            let pld_data = if (next_row_marker_predicate) { u32: 0 } else { data };
            let new_array = if (next_row_marker_predicate) { update(array, idx, array[idx] + (data*NUM_STREAMS)) } else { array };
            // SOD, EOD, EOS commands will be sent with zerod payloads, otherwise regular conversion
            let outgoing_payload_two = if (commands != u2: 0) { commands ++ uN[94]: 0 } else { u2: 0 ++ pld_index ++ new_array[idx] ++ pld_data };
            // trace_fmt!("received {:0x}", spo_pld);
            // trace_fmt!("sending to {:0x}    {:0x}",idx, outgoing_payload_two);
            let n_tok = send(tok, multistream_payload_type_two[idx], outgoing_payload_two);
            (new_array, n_tok)
        }((new_row_array, new_tok));

        (new_row_array, new_tok)
    }

}