pub proc cluster_packer<NUM_STREAMS: u32,PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}>
{
    payload_type_four:              chan<uN[64]>[NUM_STREAMS]   in;

    vector_payload_one:             chan<uN[PAYLOAD_ONE_BITWIDTH]> out;

    config(
        payload_type_four:              chan<uN[64]>[NUM_STREAMS]   in,
        vector_payload_one:             chan<uN[PAYLOAD_ONE_BITWIDTH]> out
    ) {
        (
            payload_type_four, vector_payload_one
        )
    }

    init{(
        u32: 0,                                 // 0 state variable
        zero!<u1[NUM_STREAMS]>(),               // 1 got SOD sync
        zero!<u1[NUM_STREAMS]>(),               // 2 got EOS sync
        u30: 0,                                 // 3 cluster pack idx
        join(),                                 // 4 order token
        // substate
        zero!<uN[64][NUM_STREAMS]>()            // 5 latched payload_type_four in
    )}

    next (state: (u32, u1[NUM_STREAMS], u1[NUM_STREAMS], u30, token, uN[64][NUM_STREAMS])) {
        let (vpo_tx, ptf_rx) = 
        match (state.0) {
            u32: 0 => {(false, true)},
            u32: 1 => {(true, false)},
            u32: 2 => {(true, false)},
            u32: 3 => {(false, true)},
            u32: 4 => {(true, false)},
            _ =>{(false, false)}
        };

        let vpo_pld = 
        match (state.0) {
            u32: 1 => {u2: 3 ++ uN[PAYLOAD_ONE_BITWIDTH - u32: 2]: 0},
            u32: 2 => {u2: 1 ++ uN[PAYLOAD_ONE_BITWIDTH - u32: 2]: 0},
            u32: 4 => {
                let (packed_out, seen_eod) =
                for (idx, (multistream, seen)) : (u32, (u32[NUM_STREAMS], bool)) in u32:0..NUM_STREAMS {
                    let n_seen = if (state.5[idx][62+:u2] == u2: 2) { true } else { seen };
                    let n_multistream = update(multistream, idx, state.5[idx][0+:u32]);
                    (n_multistream, n_seen)
                }((zero!<u32[NUM_STREAMS]>(), false));
                let packed_out_bits = packed_out as uN[NUM_STREAMS << 5];
                let packed_payload = u2: 0 ++ state.3 ++ packed_out_bits;
                let vpo_pld = if (seen_eod) { u2: 2 ++ uN[PAYLOAD_ONE_BITWIDTH - u32: 2]: 0 } else { packed_payload };
                (vpo_pld)
            },
            _ =>{uN[PAYLOAD_ONE_BITWIDTH]:0}
        };

        let t0 = send_if(state.4, vector_payload_one, vpo_tx, vpo_pld);
        let (t1, ptf_pld) =
        unroll_for! (idx, (tok, pld)) : (u32, (token, uN[64][NUM_STREAMS])) in u32:0..NUM_STREAMS{
            let rev_idx = NUM_STREAMS - u32: 1 - idx;
            let (n_tok, spld) = recv_if(tok, payload_type_four[rev_idx], ptf_rx, uN[64]: 0);
            let n_pld = update(pld, rev_idx, spld);
            (n_tok, n_pld)
        }((state.4, zero!<uN[64][NUM_STREAMS]>()));
        let new_tok = join(t0, t1);

        let (st0, st1, st2, st3, st5) =
        match (state.0) {
            u32: 0 => {
                let (new_sod_sync, new_eos_sync) =
                for (idx, (sod, eos)) : (u32, (u1[NUM_STREAMS], u1[NUM_STREAMS])) in u32:0..NUM_STREAMS {
                    let g_sod = ptf_pld[idx][62+:u2] == u2: 1;
                    let g_eos = ptf_pld[idx][62+:u2] == u2: 3;
                    let n_sod = if (g_sod) {update(sod, idx, g_sod) } else { sod };
                    let n_eos = if (g_eos) {update(eos, idx, g_eos) } else { eos };
                    (n_sod, n_eos)
                }((state.1, state.2));
                let got_sod = and_reduce(new_sod_sync as uN[NUM_STREAMS]);
                let got_eos = and_reduce(new_eos_sync as uN[NUM_STREAMS]);
                let new_sod_sync = if (got_sod) { zero!<u1[NUM_STREAMS]>() } else { new_sod_sync };
                let new_eos_sync = if (got_eos) { zero!<u1[NUM_STREAMS]>() } else { new_eos_sync };
                let new_pack_idx = u30: 0;
                let new_state = if (got_eos) { u32: 1 } else if (got_sod) { u32: 2 } else { state.0 };
                (new_state, new_sod_sync, new_eos_sync, new_pack_idx, state.5)
            },
            u32: 1 => {
                let new_state = u32: 0;
                (new_state, state.1, state.2, state.3, state.5)
            },
            u32: 2 => {
                let new_state = u32: 3;
                (new_state, state.1, state.2, state.3, state.5)
            },
            u32: 3 => {
                let new_state = u32: 4;
                (new_state, state.1, state.2, state.3, ptf_pld)
            },
            u32: 4 => {
                let seen_eod =
                for (idx, seen) : (u32, bool) in u32:0..NUM_STREAMS {
                    let n_seen = if (state.5[idx][62+:u2] == u2: 2) { true } else { seen };
                    (n_seen)
                }(false);
                let new_pack_idx = state.3 + u30: 1;
                let new_state = if (seen_eod) { u32: 0 } else { u32: 3 };
                (new_state, state.1, state.2, new_pack_idx, state.5)
            },
            _ => {(state.0, state.1, state.2, state.3, state.5)}
        };
        (st0, st1, st2, st3, new_tok, st5)
    }
}