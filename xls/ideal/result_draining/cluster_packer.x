pub proc cluster_packer<
    NUM_STREAMS: u32,
    PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}
>{
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
        join()                                  // 4 order token
    )}

    next (state: (u32, u1[NUM_STREAMS], u1[NUM_STREAMS], u30, token)) {
        let new_state =
        // SOD sync or EOS, send sync upon recieve
        // reset sync upon completion of sync
        if (state.0 == u32: 0) {
            let (new_tok, new_sod_sync, new_eos_sync) =
            for (idx, (tok, sod, eos)) : (u32, (token, u1[NUM_STREAMS], u1[NUM_STREAMS])) in u32:0..NUM_STREAMS {
                let (n_tok, stream_res) = recv(tok, payload_type_four[idx]);
                let g_sod = stream_res[62+:u2] == u2: 1;
                let g_eos = stream_res[62+:u2] == u2: 3;
                let n_sod = if (g_sod) { update(sod, idx, g_sod) } else { sod };
                let n_eos = if (g_eos) { update(eos, idx, g_eos) } else { eos };
                (n_tok, n_sod, n_eos)
            }((state.4, state.1, state.2));
            let got_sod = and_reduce(new_sod_sync as uN[NUM_STREAMS]);
            let got_eos = and_reduce(new_eos_sync as uN[NUM_STREAMS]);
            let new_sod_sync = if (got_sod) { zero!<u1[NUM_STREAMS]>() } else { new_sod_sync };
            let new_eos_sync = if (got_eos) { zero!<u1[NUM_STREAMS]>() } else { new_eos_sync };
            let new_tok = send_if(new_tok, vector_payload_one, got_sod, u2: 1 ++ uN[PAYLOAD_ONE_BITWIDTH - u32: 2]: 0);
            let new_tok = send_if(new_tok, vector_payload_one, got_eos, u2: 3 ++ uN[PAYLOAD_ONE_BITWIDTH - u32: 2]: 0);
            let new_pack_idx = u30: 0;
            let new_state =
            if (got_sod) { u32: 1 }
            else { state.0 }; // getting eos sync literally just sends EOS thats all.
            (
                new_state, new_sod_sync, new_eos_sync, new_pack_idx, new_tok
            )
        }
        else
        // pack results until EOD,
        // send EOD if got EOD (only a single EOD no full sync necessary, should be fully synced now)
        if (state.0 == u32: 1) {
            // generate the packed payload
            let (new_tok, packed_out, seen_eod) =
            for (idx, (tok, multistream, seen)) : (u32, (token, u32[NUM_STREAMS], bool)) in u32:0..NUM_STREAMS {
                // index is reversed because of the fact that LSB index becomes MSB bit
                let rev_idx = NUM_STREAMS - u32: 1 - idx;
                let (n_tok, stream_out) = recv(tok, payload_type_four[rev_idx]);
                let n_seen = if (stream_out[62+:u2] == u2: 2) { true } else { seen };
                let n_multistream = update(multistream, rev_idx, stream_out[0+:u32]);
                (n_tok, n_multistream, n_seen)
            }((state.4, zero!<u32[NUM_STREAMS]>(), false));
            let packed_out_bits = packed_out as uN[NUM_STREAMS << 5];
            let packed_payload = u2: 0 ++ state.3 ++ packed_out_bits;
            let base_cmd = zero!<uN[PAYLOAD_ONE_BITWIDTH]>();

            // send packed payload or EOD
            // trace_fmt!("sending {:0x} {:0x}", seen_eod, u2: 2 ++ base_cmd[0+:uN[PAYLOAD_ONE_BITWIDTH - u32: 2]]);
            // trace_fmt!("sending {:0x} {:0x}", !seen_eod, packed_payload);
            let new_tok = send_if(new_tok, vector_payload_one, seen_eod, u2: 2 ++ base_cmd[0+:uN[PAYLOAD_ONE_BITWIDTH - u32: 2]]);
            let new_tok = send_if(new_tok, vector_payload_one, !seen_eod, packed_payload);

            // update state variables
            let new_pack_idx = state.3 + u30: 1;
            let new_state = if (seen_eod) { u32: 0 } else { state.0 };
            (
                new_state, state.1, state.2, new_pack_idx, new_tok
            )
        }
        else {
            trace_fmt!("SHOULD NEVER BE IN THIS STATE!!!!");
            state
        };
        new_state
    }
}