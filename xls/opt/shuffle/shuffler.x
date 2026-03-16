import matrix_helper;

pub proc shuffler<NUM_STREAMS: u32>
{
    multistream_payload_i:                 chan<uN[96]>[NUM_STREAMS] in;
    multistream_payload_o:                 chan<uN[96]>[NUM_STREAMS] out;

    // shuffler core proc members
    shuffler_multistream__core_payload_i:                 chan<uN[96]>[NUM_STREAMS] out;
    shuffler_multistream__core_payload_o:                 chan<uN[96]>[NUM_STREAMS] in;

    config(
        multistream_payload_i:                 chan<uN[96]>[NUM_STREAMS] in,
        multistream_payload_o:                 chan<uN[96]>[NUM_STREAMS] out,
        // shuffler core proc members
        shuffler_multistream__core_payload_i:                 chan<uN[96]>[NUM_STREAMS] out,
        shuffler_multistream__core_payload_o:                 chan<uN[96]>[NUM_STREAMS] in
    ){
        (
            multistream_payload_i, multistream_payload_o, 
            shuffler_multistream__core_payload_i, shuffler_multistream__core_payload_o
        )
    }

    init{(
        u32: 0,                     // 0 the literal state
        zero!<u1[NUM_STREAMS]>(),   // 1 got EOS
        zero!<u1[NUM_STREAMS]>(),   // 2 got SOD
        zero!<u1[NUM_STREAMS]>(),   // 3 got EOD from input lane
        zero!<u1[NUM_STREAMS]>(),   // 4 got EOD from output of shuffler core
        join(),                     // 5 ordering token

        // substate (not found in original proc)
        zero!<uN[96][NUM_STREAMS]>(),   // 6 latched multistream payload
        zero!<u1[NUM_STREAMS]>(),       // 7 latched update to new_eod (cant use it too early)
        zero!<uN[96][NUM_STREAMS]>()    // 8 latched multistream core payload (i coulda used state 6 but im not gonna)
    )}

    next (state: (u32, u1[NUM_STREAMS], u1[NUM_STREAMS], u1[NUM_STREAMS], u1[NUM_STREAMS], token, uN[96][NUM_STREAMS], u1[NUM_STREAMS], uN[96][NUM_STREAMS])) {
        // state print for debugging
        // trace_fmt!(" ");
        // trace_fmt!(" current state ");
        // trace_fmt!("---------------");
        // trace_fmt!("state: {:0x}", state.0);
        // trace_fmt!("g_eos: {:0x}", state.1);
        // trace_fmt!("g_sod: {:0x}", state.2);
        // trace_fmt!("g_eod: {:0x}", state.3);
        // trace_fmt!("sg_eod: {:0x}", state.4);
        // trace_fmt!("substate_mpld: {:0x}", state.6);
        // trace_fmt!("substate_new_eod: {:0x}", state.7);
        // trace_fmt!("substate_mpcorepld: {:0x}", state.8);
        // trace_fmt!("---------------");
        // trace_fmt!(" ");
        
        // 1) Calculation of TX/RX boolean variables
        let (mp_tx, smp_tx, mp_rx, smp_rx) =
        match (state.0) {
            u32: 0 => {(false, zero!<u1[NUM_STREAMS]>(), all_ones!<u1[NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>())},
            u32: 1 => {(true, zero!<u1[NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>())},
            u32: 2 => {(false, zero!<u1[NUM_STREAMS]>(), (!(state.3 as uN[NUM_STREAMS]) as u1[NUM_STREAMS]), zero!<u1[NUM_STREAMS]>())},
            u32: 3 => {(false, (!(state.7 as uN[NUM_STREAMS]) as u1[NUM_STREAMS]), zero!<u1[NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>())},
            u32: 4 => {(false, zero!<u1[NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>(), all_ones!<u1[NUM_STREAMS]>())},
            u32: 5 => {(true, zero!<u1[NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>())},
            u32: 6 => {(false, zero!<u1[NUM_STREAMS]>(), all_ones!<u1[NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>())},  // <-- interesting that in this and shuffle.x, 
                                                                                                                    // i dont sync on SOD over multiple activiations (it must be immediate)
            u32: 7 => {(true, zero!<u1[NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>())},
            _ => {(false, zero!<u1[NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>())}
        };

        // 2) Calculation of send payloads
        let (mpo_pld, smpo_pld) =
        match (state.0) {
            u32: 1 => {
                let mpo_pld =
                for (idx, pld) : (u32, uN[96][NUM_STREAMS]) in u32:0..NUM_STREAMS {
                    let n_pld = update(pld, idx, u2: 1 ++ uN[94]: 0);
                    (n_pld)
                }(zero!<uN[96][NUM_STREAMS]>());
                (mpo_pld, zero!<uN[96][NUM_STREAMS]>())
            },
            u32: 3 => {(zero!<uN[96][NUM_STREAMS]>(), state.6)},
            u32: 5 => {(state.8, zero!<uN[96][NUM_STREAMS]>())},
            u32: 7 => {
                let mpo_pld =
                for (idx, pld) : (u32, uN[96][NUM_STREAMS]) in u32:0..NUM_STREAMS {
                    let n_pld = update(pld, idx, u2: 3 ++ uN[94]: 0);
                    (n_pld)
                }(zero!<uN[96][NUM_STREAMS]>());
                (mpo_pld, zero!<uN[96][NUM_STREAMS]>())
            },
            _ => {(zero!<uN[96][NUM_STREAMS]>(), zero!<uN[96][NUM_STREAMS]>())}
        };

        // 3) Sends and Receives.
        let t1 =
        unroll_for! (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
            let n_tok = send_if(tok, multistream_payload_o[idx], mp_tx, mpo_pld[idx]);
            (n_tok)
        }(state.5);
        let t2 =
        unroll_for! (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
            let n_tok = send_if(tok, shuffler_multistream__core_payload_i[idx], smp_tx[idx] == u1: 1, smpo_pld[idx]);
            (n_tok)
        }(state.5);
        let (t3, mp_pld) =
        unroll_for! (idx, (tok, mp)) : (u32, (token, uN[96][NUM_STREAMS])) in u32:0..NUM_STREAMS {
            let (n_tok, sp) = recv_if(tok, multistream_payload_i[idx], mp_rx[idx] == u1: 1, zero!<uN[96]>()); // note mp_rx must be an array
            let n_mp = update(mp, idx, sp);
            (n_tok, n_mp)
        }((state.5, zero!<uN[96][NUM_STREAMS]>()));
        let (t4, smp_pld) =
        unroll_for! (idx, (tok, mp)) : (u32, (token, uN[96][NUM_STREAMS])) in u32:0..NUM_STREAMS {
            let (n_tok, sp) = recv_if(tok, shuffler_multistream__core_payload_o[idx], smp_rx[idx] == u1: 1, zero!<uN[96]>());
            let n_mp = update(mp, idx, sp);
            (n_tok, n_mp)
        }((state.5, zero!<uN[96][NUM_STREAMS]>()));
        let new_tok = join(t1, t2, t3, t4);

        // 4) State updates
        let (st0, st1, st2, st3, st4, st6, st7, st8) = // skipping state 5
        match (state.0) {
            u32: 0 => {
                let new_sod =
                for (idx, sod): (u32, u1[NUM_STREAMS]) in u32:0..NUM_STREAMS{
                    let n_sod =
                    if (mp_pld[idx][94+:u2] == u2:1){
                        update(sod, idx, u1: 1)
                    } else {
                        sod
                    };
                    (n_sod)
                }(state.2);
                let new_state = if (and_reduce(new_sod as uN[NUM_STREAMS])) { u32: 1 } else { state.0 };
                (new_state, state.1, new_sod, state.3, state.4, state.6, state.7, state.8)
            },
            u32: 1 => {
                let new_sod = zero!<u1[NUM_STREAMS]>();
                let new_eod = zero!<u1[NUM_STREAMS]>();
                let new_shuffler_eod = zero!<u1[NUM_STREAMS]>();
                let new_state = u32: 2;
                (new_state, state.1, new_sod, new_eod, new_shuffler_eod, state.6, state.7, state.8)
            },
            u32: 2 => {
                let new_state = u32: 3;
                let new_eod = 
                for (idx, eod) : (u32, u1[NUM_STREAMS]) in u32:0..NUM_STREAMS {
                    let n_eod_p = mp_pld[idx][94+:u2] == u2:2;
                    let n_eod = if (n_eod_p) { update(eod, idx, n_eod_p) } else { eod };
                    (n_eod)
                }(state.3);
                (new_state, state.1, state.2, new_eod, state.4, mp_pld, state.3, state.8) // save the old state.3 so that we dont mess up state 3
            },
            u32: 3 => {
                let new_state = u32: 4;
                (new_state, state.1, state.2, state.3, state.4, state.6, state.7, state.8)
            },
            u32: 4 => {
                let new_shuffler_eod = 
                for (idx, eod) : (u32, u1[NUM_STREAMS]) in u32:0..NUM_STREAMS {
                    let n_eod_p = smp_pld[idx][94+:u2] == u2:2;
                    let n_eod = if (n_eod_p) { update(eod, idx, n_eod_p) } else { eod };
                    (n_eod)
                }(state.4);
                let new_state = u32: 5;
                (new_state, state.1, state.2, state.3, new_shuffler_eod, state.6, state.7, smp_pld)
            },
            u32: 5 => {
                let eod_predicate_shuffle_output = and_reduce(state.4 as uN[NUM_STREAMS]);
                let new_state = if (eod_predicate_shuffle_output) { u32: 6 } else { u32: 2 };
                (new_state, state.1, state.2, state.3, state.4, state.6, state.7, state.8)
            },
            u32: 6 => {
                let (new_sod, new_eos) = 
                for (idx, (sod, eos)): (u32, (u1[NUM_STREAMS], u1[NUM_STREAMS])) in u32:0..NUM_STREAMS{
                    let new_sod_p = mp_pld[idx][94+:u2] == u2:1;
                    let new_eos_p = mp_pld[idx][94+:u2] == u2:3;
                    let n_sod = update(sod, idx, new_sod_p);
                    let n_eos = update(eos, idx, new_eos_p);
                    (n_sod, n_eos)
                }((state.2, state.1));
                let sod_predicate = and_reduce(new_sod as uN[NUM_STREAMS]);
                let eos_predicate = and_reduce(new_eos as uN[NUM_STREAMS]);
                // only one predicate should be true at a time, so it should be
                // okay that this is a sequential if condition
                // again note that i require this state to complete in one activation
                let new_state =
                if (sod_predicate){ u32: 1 }
                else if (eos_predicate){ u32: 7 }
                else { u32: 98 }; // <-- needs to be a better way to signal errors
                (new_state, new_eos, new_sod, state.3, state.4, state.6, state.7, state.8)
            },
            u32: 7 => {
                let new_state = u32: 1;
                (new_state, state.1, state.2, state.3, state.4, state.6, state.7, state.8)},
            _ => {(state.0, state.1, state.2, state.3, state.4, state.6, state.7, state.8)}
        };
        (st0, st1, st2, st3, st4, new_tok, st6, st7, st8)
    }
}