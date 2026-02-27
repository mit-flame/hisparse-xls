import arbiter;
import crossbar;
import matrix_helper;

pub proc shuffler_core<
    NUM_STREAMS: u32,
    FLUSH_ITERS: u32 = { u32: 8 } // this will be dependent on the synthesized arbiter pipeline depth
>{
    multistream_payload_i:                 chan<uN[96]>[NUM_STREAMS] in;
    multistream_payload_o:                 chan<uN[96]>[NUM_STREAMS] out;

    // arbiter proc members
    arbiter_payload_type_two_i:         chan<uN[96][NUM_STREAMS]> out;
    arbiter_i_valid:                    chan<u1[NUM_STREAMS]>     out;
    arbiter_rotate_offset:              chan<u32>                 out;
    arbiter_resend_payload_type_two:    chan<uN[96][NUM_STREAMS]> in;
    arbiter_resend_payload_valid:       chan<u1[NUM_STREAMS]>     in;
    arbiter_xbar_select:                chan<u32[NUM_STREAMS]>    in;
    arbiter_xbar_valid:                 chan<u1[NUM_STREAMS]>     in;
    arbiter_original_input_valid:       chan<u1[NUM_STREAMS]>     in;

    // seems like the crossbar doesnt introduce additional members
    // also, as of right now, crossbar is expected to run within one activation
    // that might be a problem later

    config(
        multistream_payload_i:       chan<uN[96]>[NUM_STREAMS] in,
        multistream_payload_o:       chan<uN[96]>[NUM_STREAMS] out
    ) { 
        let (aptto, aptti) = chan<uN[96][NUM_STREAMS]>("arbiter_aptt");
        let (aivo, aivi) = chan<u1[NUM_STREAMS]>("arbiter_aiv");
        let (aroo, aroi) = chan<u32>("arbiter_aro");
        let (arptto, arptti) = chan<uN[96][NUM_STREAMS]>("arbiter_arptt");
        let (arpvo, arpvi) = chan<u1[NUM_STREAMS]>("arbiter_arpv");
        let (axso, axsi) = chan<u32[NUM_STREAMS]>("arbiter_axs");
        let (axvo, axvi) = chan<u1[NUM_STREAMS]>("arbiter_axv");
        let (aoivo, aoivi) = chan<u1[NUM_STREAMS]>("arbiter_aoiv");
        spawn arbiter::arbiter_wrapper<NUM_STREAMS>(aptti, aivi, aroi, arptto, arpvo, axso, axvo, aoivo);
        (
            // outward facing proc members
            multistream_payload_i, multistream_payload_o,
            // child proc's members
            aptto, aivo, aroo, arptti, arpvi, axsi, axvi, aoivi
        )
    }

    init {(
        u32: 0,                         // 0 the actual state
        zero!<u1[NUM_STREAMS]>(),       // 1 fetch complete
        FLUSH_ITERS,                    // 2 counter counting down from FLUSH_ITERS during flushing state
        u32: 0,                         // 3 rotate priority
        join()                          // 4 token incase we need to order events between activations
        // payloads (reg and resend) should not be stateful
        // as the arbiter pipeline holds their state.
        // likewise, when the arbiter is first starting, we can simply
        // do nonblocking recv's to filter out the dead values
    )}

    // !!! anything that isnt either updated or reset by a given state must be passed through by said state !!!
    next (state: (u32, u1[NUM_STREAMS], u32, u32, token)) {

        // state print for debugging
        // trace_fmt!(" ");
        // trace_fmt!(" current state ");
        // trace_fmt!("---------------");
        // trace_fmt!("state  : {:0x}", state.0);
        // trace_fmt!("fetch_c: {:0x}", state.1);
        // trace_fmt!("f_count: {:0x}", state.2);
        // trace_fmt!("rotate : {:0x}", state.3);
        // trace_fmt!("---------------");
        // trace_fmt!(" ");
        // trace_fmt!(" ");

        let new_state =
        // regular "Fetch" stage, 
        if (state.0 == u32: 0) {
            // non blocking grab (because arbiter could be just starting up) of all arbiter outputs
            let (new_tok1, arb_resend_valid, arb_resend_valid_real) = recv_non_blocking(state.4, arbiter_resend_payload_valid, zero!<u1[NUM_STREAMS]>());
            let (new_tok2, arb_resend_payload, arb_resend_payload_real) = recv_non_blocking(state.4, arbiter_resend_payload_type_two, zero!<uN[96][NUM_STREAMS]>());
            let (new_tok3, xbar_s, xbar_s_real) = recv_non_blocking(state.4, arbiter_xbar_select, zero!<u32[NUM_STREAMS]>());
            let (new_tok4, xbar_v, xbar_v_real) = recv_non_blocking(state.4, arbiter_xbar_valid, zero!<u1[NUM_STREAMS]>());
            let (new_tok5, arb_original_input_valid, arb_og_valid_real) = recv_non_blocking(state.4, arbiter_original_input_valid, zero!<u1[NUM_STREAMS]>());
            // blocking grab of the input payload type two, conditional on the read_input_predcate
            let (new_tok6, payload_two_in) = 
            for (idx, (tok, payload_two)) : (u32, (token, uN[96][NUM_STREAMS])) in u32:0..NUM_STREAMS {
                let read_input_predicate = !arb_resend_valid[idx] && !state.1[idx];
                let (n_tok, stream_payload_two) = recv_if(tok, multistream_payload_i[idx], read_input_predicate, zero!<uN[96]>());
                let n_payload_two = update(payload_two, idx, stream_payload_two);
                (n_tok, n_payload_two)
            }((state.4, zero!<uN[96][NUM_STREAMS]>()));
            // trace_fmt!("shuffler_core in: {:0x}", payload_two_in);
            let new_tok = join(new_tok1, new_tok2, new_tok3, new_tok4, new_tok5, new_tok6);
            // creation of the next payload to send to the arbiter pipeline (plus update fetch complete)
            let (new_valid, new_payload, new_fetch_complete) =
            for (idx, (valid, payload, fetch_complete)) : (u32, (u1[NUM_STREAMS], uN[96][NUM_STREAMS], u1[NUM_STREAMS])) in u32:0..NUM_STREAMS {
                let resend_predicate = arb_resend_valid[idx];
                // all resend packets OR all packets that are not EOD inst NOR fetch already is complete
                let valid_predicate = resend_predicate || (payload_two_in[idx][94+:u2] != u2:2 && !state.1[idx] && payload_two_in[idx][0+:u32] != u32: 0); // <------- change: require data to be nonzero for validity
                // either the fetch was already complete or it just completed
                let fetch_complete_predicate = state.1[idx] || payload_two_in[idx][94+:u2] == u2:2;
                let p = if (resend_predicate) { arb_resend_payload[idx] } else { payload_two_in[idx] };
                let new_v = update(valid, idx, valid_predicate);
                let new_p = update(payload, idx, p);
                let new_f_c = update(fetch_complete, idx, fetch_complete_predicate);
                (new_v, new_p, new_f_c)
            }((zero!<u1[NUM_STREAMS]>(), zero!<uN[96][NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>()));
            // trigger the arbiter
            // trace_fmt!("input valid {:0x}", new_valid);
            let new_tok1 = send(new_tok, arbiter_payload_type_two_i, new_payload);
            let new_tok2 = send(new_tok, arbiter_i_valid, new_valid);
            let new_tok3 = send(new_tok, arbiter_rotate_offset, state.3);
            // trigger the crossbar using the arbiters outputs.
            // to rectify my confusion, I diverged from hisparse imp and had the arbiter pipeline the original
            // valid signal
            // trace_fmt!("crossbar inputs plus resend valid:");
            // trace_fmt!("arb_resend_payload : {:0x}", arb_resend_payload); // <------------------- why is this duplicating the granted one
            // trace_fmt!("arb_original_input_valid : {:0x}", arb_original_input_valid);
            // trace_fmt!("xbar_v : {:0x}", xbar_v);
            // trace_fmt!("xbar_s : {:0x}", xbar_s);
            // trace_fmt!("arb_resend_valid: {:0x}", arb_resend_valid);

            let crossbar_payload_type_two = crossbar::crossbar<NUM_STREAMS>(arb_resend_payload, arb_original_input_valid, xbar_v, xbar_s);
            // send the crossbars output out
            let new_tok4 =
            for (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
                let n_tok4 = send(tok, multistream_payload_o[idx], crossbar_payload_type_two[idx]);
                (n_tok4)
            }(new_tok);
            // state calculation
            let new_tok = join(new_tok1, new_tok2, new_tok3, new_tok4);
            let next_rotate_priority = (state.3 + u32: 1) % NUM_STREAMS;
            let new_state = if (and_reduce(new_fetch_complete as uN[NUM_STREAMS])) { u32: 1 } else { u32: 0 };
            (
                new_state, new_fetch_complete, state.2,
                next_rotate_priority, new_tok
            )
        }
        else
        // draining stage, fetch is complete so we just sample the arbiter output and 
        // shunt it to the crossbar, while feeding the arbiter all zeros.
        if (state.0 == u32: 1){
            let (new_tok1, arb_resend_valid, arb_resend_valid_real) = recv_non_blocking(state.4, arbiter_resend_payload_valid, zero!<u1[NUM_STREAMS]>());
            let (new_tok2, arb_resend_payload, arb_resend_payload_real) = recv_non_blocking(state.4, arbiter_resend_payload_type_two, zero!<uN[96][NUM_STREAMS]>());
            let (new_tok3, xbar_s, xbar_s_real) = recv_non_blocking(state.4, arbiter_xbar_select, zero!<u32[NUM_STREAMS]>());
            let (new_tok4, xbar_v, xbar_v_real) = recv_non_blocking(state.4, arbiter_xbar_valid, zero!<u1[NUM_STREAMS]>());
            let (new_tok5, arb_original_input_valid, arb_og_valid_real) = recv_non_blocking(state.4, arbiter_original_input_valid, zero!<u1[NUM_STREAMS]>());
            let new_tok = join(new_tok1, new_tok2, new_tok3, new_tok4, new_tok5);
            let new_valid = zero!<u1[NUM_STREAMS]>();
            let new_payload = zero!<uN[96][NUM_STREAMS]>();
            // trigger the arbiter
            let new_tok1 = send(new_tok, arbiter_payload_type_two_i, new_payload);
            let new_tok2 = send(new_tok, arbiter_i_valid, new_valid);
            let new_tok3 = send(new_tok, arbiter_rotate_offset, state.3);
            // trigger crossbar and send output
            let crossbar_payload_type_two = crossbar::crossbar<NUM_STREAMS>(arb_resend_payload, arb_original_input_valid, xbar_v, xbar_s);
            let new_tok4 =
            for (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
                let n_tok4 = send(tok, multistream_payload_o[idx], crossbar_payload_type_two[idx]);
                (n_tok4)
            }(new_tok);
            let new_tok = join(new_tok1, new_tok2, new_tok3, new_tok4);
            // state calculation
            let new_flush_counter = state.2 - u32: 1;
            let next_rotate_priority = (state.3 + u32: 1) % NUM_STREAMS;
            let new_state = if (new_flush_counter == u32: 0) { u32: 2 } else { u32: 1 };
            (
                new_state, state.1, new_flush_counter,
                next_rotate_priority, new_tok
            )
        }
        else
        if (state.0 == u32: 2){
            // loop exit state, send EOD once then jump back to state.0
            let new_tok =
            for (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
                let n_tok = send(tok, multistream_payload_o[idx], matrix_helper::payload_converter<NUM_STREAMS>(zero!<uN[64]>(), u32: 0, u2: 2));
                (n_tok)
            }(state.4);
            let new_state = u32: 0;
            (
                new_state, zero!<u1[NUM_STREAMS]>(), FLUSH_ITERS,
                u32: 0, new_tok
            )
        }
        else {
            // should never happen
            trace_fmt!("THIS STATE SHOULD NEVER OCCUR!!!!!!!!!!!!!!!!");
            (u32: 0, zero!<u1[NUM_STREAMS]>(), u32: 0, u32: 0, join())
        };
        (new_state)
    }

}