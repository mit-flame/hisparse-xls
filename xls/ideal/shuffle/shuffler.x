import shuffler_core;
import matrix_helper;

pub proc shuffler<
    NUM_STREAMS: u32
>{
    multistream_payload_i:                 chan<uN[96]>[NUM_STREAMS] in;
    multistream_payload_o:                 chan<uN[96]>[NUM_STREAMS] out;

    // shuffler core proc members
    shuffler_multistream__core_payload_i:                 chan<uN[96]>[NUM_STREAMS] out;
    shuffler_multistream__core_payload_o:                 chan<uN[96]>[NUM_STREAMS] in;

    config(
        multistream_payload_i:                 chan<uN[96]>[NUM_STREAMS] in,
        multistream_payload_o:                 chan<uN[96]>[NUM_STREAMS] out
    ){
        let (scpttio, scpttii) = chan<uN[96]>[NUM_STREAMS]("scptti");
        let (scpttoo, scpttoi) = chan<uN[96]>[NUM_STREAMS]("scptto");
        spawn shuffler_core::shuffler_core<NUM_STREAMS>(scpttii, scpttoo);
        (
            multistream_payload_i, multistream_payload_o, scpttio, scpttoi
        )
    }

    init{(
        u32: 0,                     // 0 the literal state
        zero!<u1[NUM_STREAMS]>(),   // 1 got EOS
        zero!<u1[NUM_STREAMS]>(),   // 2 got SOD
        zero!<u1[NUM_STREAMS]>(),   // 3 got EOD from input lane
        zero!<u1[NUM_STREAMS]>(),   // 4 got EOD from output of shuffler core
        join()                      // 5 ordering token
    )}

    // !!! anything that isnt either updated or reset by a given state must be passed through by said state !!!
    next (state: (u32, u1[NUM_STREAMS], u1[NUM_STREAMS], u1[NUM_STREAMS], u1[NUM_STREAMS], token)) {

        // state print for debugging
        // trace_fmt!(" ");
        // trace_fmt!(" current state ");
        // trace_fmt!("---------------");
        // trace_fmt!("state: {:0x}", state.0);
        // trace_fmt!("g_eos: {:0x}", state.1);
        // trace_fmt!("g_sod: {:0x}", state.2);
        // trace_fmt!("g_eod: {:0x}", state.3);
        // trace_fmt!("---------------");
        // trace_fmt!(" ");


        let new_state = 
        // first launch sync on SOD
        if (state.0 == u32: 0){
            // i dont see why we cant do a blocking read here
            let (new_tok, new_sod) =
            for (idx, (tok, sod)) : (u32, (token, u1[NUM_STREAMS])) in u32:0..NUM_STREAMS{
                let (n_tok, payload_two) = recv(state.5, multistream_payload_i[idx]);
                let n_sod =
                if (payload_two[94+:u2] == u2:1){
                    update(sod, idx, u1: 1)
                } else {
                    sod
                };
                (n_tok, n_sod)
            }((state.5, state.2));
            let new_state = if (and_reduce(new_sod as uN[NUM_STREAMS])) { u32: 1 } else { state.0 };
            (
                new_state, state.1, new_sod, state.3, state.4, new_tok
            )
        }
        else
        // send SOD, reset SOD, EOD and shuffler EOD
        if (state.0 == u32: 1){
            let new_tok =
            for (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
                let n_tok = send(tok, multistream_payload_o[idx], matrix_helper::payload_converter<NUM_STREAMS>(zero!<uN[64]>(), u32: 0, u2: 1));
                (n_tok)
            }(state.5);
            let new_sod = zero!<u1[NUM_STREAMS]>();
            let new_eod = zero!<u1[NUM_STREAMS]>();
            let new_shuffler_eod = zero!<u1[NUM_STREAMS]>();
            let new_state = u32: 2;
            (
                new_state, state.1, new_sod, new_eod, new_shuffler_eod, new_tok
            )
        }
        else
        // run shuffler core to output lanes until shuffler core outputs EOD
        if (state.0 == u32: 2){
            // to mimic the reference imp, we only do the pass through to the shuffler
            // when the predicate is true
            let (new_tok, new_eod) =
            for (idx, (tok, eod)) : (u32, (token, u1[NUM_STREAMS])) in u32:0..NUM_STREAMS {
                let (n_tok, stream_payload_two) = recv_if(tok, multistream_payload_i[idx], !state.3[idx], zero!<uN[96]>());
                // trace_fmt!("sending to shuffler_core lane {}: {:0x} the payload {:0x} ", idx, !state.3[idx], stream_payload_two);
                // trace_fmt!(" ");
                let n_tok = send_if(n_tok, shuffler_multistream__core_payload_i[idx], !state.3[idx], stream_payload_two);
                let n_eod_p = stream_payload_two[94+:u2] == u2:2;
                let n_eod = if (n_eod_p) { update(eod, idx, n_eod_p) } else { eod };
                (n_tok, n_eod)
            }((state.5, state.3));

            let (new_tok, shuffle_core_payload_two) =
            for (idx, (tok, payload_two)) : (u32, (token, uN[96][NUM_STREAMS])) in u32:0..NUM_STREAMS {
                let (n_tok, shuffle_core_stream_payload_two) = recv(tok, shuffler_multistream__core_payload_o[idx]);
                // trace_fmt!("shuffler received {:0x} from shuffler_core lane {}", shuffle_core_stream_payload_two, idx);
                let n_tok = send(n_tok, multistream_payload_o[idx], shuffle_core_stream_payload_two);
                let n_payload_two = update(payload_two, idx, shuffle_core_stream_payload_two);
                (n_tok, n_payload_two)
            }((new_tok, zero!<uN[96][NUM_STREAMS]>()));

            let new_shuffler_core_eod = 
            for (idx, eod): (u32, u1[NUM_STREAMS]) in u32:0..NUM_STREAMS{
                let new_eod_p = shuffle_core_payload_two[idx][94+:u2] == u2:2;
                let n_eod = update(eod, idx, new_eod_p);
                (n_eod)
            }(state.4);
            let eod_predicate_shuffle_output = and_reduce(new_shuffler_core_eod as uN[NUM_STREAMS]);
            let new_state = if (eod_predicate_shuffle_output) { u32: 3 } else { state.0 };
            (
                new_state, state.1, state.2, new_eod, new_shuffler_core_eod, new_tok
            )
        }
        else
        // sync on SOD and goto state 1 or sync on EOS and goto state 4
        if (state.0 == u32: 3){
            let (new_tok, payload_two) =
            for (idx, (tok, payload)) : (u32, (token, uN[96][NUM_STREAMS])) in u32:0..NUM_STREAMS{
                let (n_tok, stream_payload_two) = recv(tok, multistream_payload_i[idx]);
                let n_payload = update(payload, idx, stream_payload_two);
                (n_tok, n_payload)
            }((state.5, zero!<uN[96][NUM_STREAMS]>()));
            let new_sod = 
            for (idx, sod): (u32, u1[NUM_STREAMS]) in u32:0..NUM_STREAMS{
                let new_sod_p = payload_two[idx][94+:u2] == u2:1;
                let n_sod = update(sod, idx, new_sod_p);
                (n_sod)
            }(state.2);
            let sod_predicate = and_reduce(new_sod as uN[NUM_STREAMS]);
            let new_eos = 
            for (idx, eos): (u32, u1[NUM_STREAMS]) in u32:0..NUM_STREAMS{
                let new_eos_p = payload_two[idx][94+:u2] == u2:3;
                let n_eos = update(eos, idx, new_eos_p);
                (n_eos)
            }(state.1);
            let eos_predicate = and_reduce(new_eos as uN[NUM_STREAMS]);
            // only one predicate should be true at a time, so it should be
            // okay that this is a sequential if condition
            let new_state =
            if (sod_predicate){ u32: 1 }
            else if (eos_predicate){ u32: 4 }
            else { u32: 98 }; // again kick to random state for error, i suppose these numbers serve as error codes!
            (
                new_state, new_eos, new_sod, state.3, state.4, new_tok
            )
        }
        else
        // send EOS
        if (state.0 == u32: 4){
            let new_tok =
            for (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
                let n_tok = send(tok, multistream_payload_o[idx], matrix_helper::payload_converter<NUM_STREAMS>(zero!<uN[64]>(), u32: 0, u2: 3));
                (n_tok)
            }(state.5);
            let new_state = u32: 0;
            let new_got_eos = zero!<u1[NUM_STREAMS]>();
            (
                new_state, new_got_eos, state.2, state.3, state.4, new_tok
            ) 
        }
        else {
            trace_fmt!("THIS STATE SHOULD NEVER BE ACTIVE!!!!!!!!!!!!!!!!!!!!!");
            trace_fmt!("error state: {:0x}", state.0);
            (
                state.0, state.1, state.2, state.3, state.4, state.5
            )
        };
        (new_state)
    }
}