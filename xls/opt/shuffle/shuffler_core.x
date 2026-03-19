import crossbar;
import matrix_helper;
import arbiter_helper;

pub proc shuffler_core <NUM_STREAMS: u32, FLUSH_ITERS: u32> // this will be dependent on the synthesized arbiter pipeline depth
{
    multistream_payload_i:                 chan<uN[96]>[NUM_STREAMS] in;
    multistream_payload_o:                 chan<uN[96]>[NUM_STREAMS] out;

    // arbiter proc members
    arbiter_payload_type_two_i:         chan<uN[96][NUM_STREAMS]> out;
    arbiter_i_valid:                    chan<u1[NUM_STREAMS]>     out;
    arbiter_rotate_offset:              chan<u32>                 out;
    arbiter_combined_out:                chan<arbiter_helper::ArbOut<NUM_STREAMS>> in;

    config(
        multistream_payload_i:       chan<uN[96]>[NUM_STREAMS] in,
        multistream_payload_o:       chan<uN[96]>[NUM_STREAMS] out,

        // externally synthesized arbiter
        arbiter_payload_type_two_i:         chan<uN[96][NUM_STREAMS]> out,
        arbiter_i_valid:                    chan<u1[NUM_STREAMS]>     out,
        arbiter_rotate_offset:              chan<u32>                 out,
        arbiter_combined_out:                chan<arbiter_helper::ArbOut<NUM_STREAMS>> in
    ) {
        (
            multistream_payload_i, multistream_payload_o,

            arbiter_payload_type_two_i, arbiter_i_valid, arbiter_rotate_offset, arbiter_combined_out
        )
    }

    init {(
        u32: 0,                             // 0 the actual state
        zero!<u1[NUM_STREAMS]>(),                    // 1 fetch complete
        FLUSH_ITERS,                        // 2 flush counter
        u32: 0,                             // 3 rotate prioritiy
        join(),                             // 4 order token
        false                               // sent EOD
    )}

    next (state: (u32, u1[NUM_STREAMS], u32, u32, token, bool)) {
        let (new_tok, arbout_pld, _) = recv_non_blocking(state.4, arbiter_combined_out, zero!<arbiter_helper::ArbOut<NUM_STREAMS>>());
        let arpv_pld = arbout_pld.rpv;
        let arptt_pld = arbout_pld.rptt;
        let axs_pld = arbout_pld.xs;
        let axv_pld = arbout_pld.xv;
        let aoiv_pld = arbout_pld.oiv;
        let (new_tok, mp_pld) =
        unroll_for! (idx, (tok, mp)) : (u32, (token, uN[96][NUM_STREAMS])) in u32:0..NUM_STREAMS {
            let read_input_predicate = !arpv_pld[idx] && !state.1[idx];
            let (n_tok, sp) = recv_if(tok, multistream_payload_i[idx], read_input_predicate, zero!<uN[96]>()); // note mp_rx must be an array
            let n_mp = update(mp, idx, sp);
            (n_tok, n_mp)
        }((new_tok, zero!<uN[96][NUM_STREAMS]>()));

        let new_fetch_complete = 
        for (idx, fc) : (u32, u1[NUM_STREAMS]) in u32:0..NUM_STREAMS {
            let n_fc = if (mp_pld[idx][94+:u2] == u2: 2) { update(fc, idx, u1: 1) } else if ( state.2 == u32: 0 ) { update(fc, idx, u1: 0) } else { fc }; 
            (n_fc)
        }(state.1);
        let next_rotate_priority = (state.3 + u32: 1) % NUM_STREAMS;
        let new_flush_counter = if (and_reduce(state.1 as uN[NUM_STREAMS])) { if (state.2 == u32: 0) { FLUSH_ITERS } else { state.2 - 1 } } else { state.2 };

        let (arb_payload_in, arb_payload_valid) =
        for (idx, (payload, valid)) : (u32, (uN[96][NUM_STREAMS], u1[NUM_STREAMS])) in u32:0..NUM_STREAMS {
            let n_valid = 
            if (arpv_pld[idx]) { update(valid, idx, u1: 1) }
            else if (mp_pld[idx][0+:u32] != u32: 0) { update(valid, idx, u1: 1) }
            else { update(valid, idx, u1: 0) };
            let p =
            if (arpv_pld[idx] == u1: 1) { arptt_pld[idx] }
            else if (mp_pld[idx][94+:u2] == u2: 3) {uN[96]: 0}
            else { mp_pld[idx] };
            let n_payload = update(payload, idx, p);
            (n_payload, n_valid)
        }((zero!<uN[96][NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>()));

        let tok1 = send(new_tok, arbiter_payload_type_two_i, arb_payload_in);
        let tok2 = send(new_tok, arbiter_i_valid, arb_payload_valid);
        let tok3 = send(new_tok, arbiter_rotate_offset, state.3);

        let crossbar_payload_type_two = crossbar::crossbar<NUM_STREAMS>(arptt_pld, aoiv_pld, axv_pld, axs_pld);
        let send_eod_predicate = and_reduce(state.1 as uN[NUM_STREAMS]) && state.2 == u32: 0;
        let new_sent_eod = if (send_eod_predicate && !state.5) { true } else { false };
        let (tok4, debug_send) = 
        unroll_for! (idx, (tok, debug)) : (u32, (token, uN[96][NUM_STREAMS])) in u32:0..NUM_STREAMS{
            let pld = if (send_eod_predicate) { u2: 2 ++ uN[94]:0 } else if (state.5 && mp_pld[u32: 0][94+:u2] == u2: 3) {  u2: 3 ++ uN[94]:0 } else { crossbar_payload_type_two[idx] };
            let n_tok = send(tok, multistream_payload_o[idx], pld);
            let n_debug = update(debug, idx, pld);
            (n_tok, n_debug)
        }((new_tok, zero!<uN[96][NUM_STREAMS]>()));
        
        let new_tok = join(tok1, tok2, tok3, tok4);
        // trace_fmt!("{:0x} current state {:0x} {:0x} {:0x} {:0x}", DEBUG_NAME, state.0, state.1, state.2, state.3);
        // trace_fmt!("{:0x} arb recv {:0x}\n{:0x} mp recv {:0x}\narb send {:0x} {:0x}\n{:0x} mp send {:0x}", DEBUG_NAME, arbout_pld, DEBUG_NAME, mp_pld, arb_payload_in, arb_payload_valid, DEBUG_NAME, debug_send);
        (state.0, new_fetch_complete, new_flush_counter, next_rotate_priority, new_tok, new_sent_eod)
    }
}