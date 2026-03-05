// equivalent to axis_merge in the hisparse source stream_utils.h
pub proc clusters_results_merger<NUM_CLUSTERS: u32, NUM_STREAMS: u32, PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}>
{
    multistream_vector_payload_one:                 chan<uN[PAYLOAD_ONE_BITWIDTH]>[NUM_CLUSTERS] in;
    vector_payload_one:                             chan<uN[PAYLOAD_ONE_BITWIDTH]> out;

    config(
        multistream_vector_payload_one:                 chan<uN[PAYLOAD_ONE_BITWIDTH]>[NUM_CLUSTERS] in,
        vector_payload_one:                             chan<uN[PAYLOAD_ONE_BITWIDTH]> out
    ) {
        (multistream_vector_payload_one, vector_payload_one)
    }

    init{(
        u32: 0,                         // 0 state
        u32: 0,                         // 1 cluster index
        u30: 0,                         // 2 payload index
        zero!<u1[NUM_CLUSTERS]>(),      // 3 got EOS
        join(),                         // 4 order token
        // substate
        zero!<uN[PAYLOAD_ONE_BITWIDTH][NUM_CLUSTERS]>()     // 5 latched multistream_vector_payload_one
    )}

    next (state: (u32, u32, u30, u1[NUM_CLUSTERS], token, uN[PAYLOAD_ONE_BITWIDTH][NUM_CLUSTERS])) {
        let (vpo_tx, mvpo_rx) =
        match (state.0) {
            u32: 0 => {(false, update(zero!<u1[NUM_CLUSTERS]>(), state.1, u1: 1))},
            u32: 1 => {
                let got_eos = state.5[state.1][(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 3;
                (!got_eos, zero!<u1[NUM_CLUSTERS]>())
            },
            u32: 2 => {(true, zero!<u1[NUM_CLUSTERS]>())},
            _ => {(false, zero!<u1[NUM_CLUSTERS]>())}
        };

        let vpo_pld = 
        match (state.0) {
            u32: 1 => {state.5[state.1][(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] ++ state.2 ++ state.5[state.1][:(NUM_STREAMS << u32: 5) as s32]},
            u32: 2 => {u2: 3 ++ u30: 0 ++ uN[(NUM_STREAMS << u32: 5)]:0},
            _ => {uN[PAYLOAD_ONE_BITWIDTH]: 0}
        };

        let t0 = send_if(state.4, vector_payload_one, vpo_tx, vpo_pld);
        let (t1, mvpo_pld) = 
        unroll_for! (idx, (tok, pld)) : (u32, (token, uN[PAYLOAD_ONE_BITWIDTH][NUM_CLUSTERS])) in u32:0..NUM_CLUSTERS {
            let (tok, spld) = recv_if(tok, multistream_vector_payload_one[idx], mvpo_rx[idx] == u1: 1, uN[PAYLOAD_ONE_BITWIDTH]: 0);
            let n_pld = update(pld, idx, spld);
            (tok, n_pld)
        }((state.4, zero!<uN[PAYLOAD_ONE_BITWIDTH][NUM_CLUSTERS]>()));
        let new_tok = join(t0, t1);

        let (st0, st1, st2, st3, st5) =
        match (state.0) {
            u32: 0 => {
                let new_state = u32: 1;
                (new_state, state.1, state.2, state.3, mvpo_pld)
            },
            u32: 1 => {
                let payload_index_incremented = ( state.2 + u30: 1 );
                let new_cluster_index = ( state.1 + u32: 1 ) % NUM_CLUSTERS;
                let got_eos = state.5[state.1][(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 3;
                let new_got_eos = if (got_eos) { update(state.3, state.1, got_eos) } else { state.3 };
                let new_payload_index = if (state.5[state.1][(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 0) { payload_index_incremented } else{ state.2 };
                let new_state = if (and_reduce(new_got_eos as uN[NUM_CLUSTERS])) { u32: 2 } else { u32: 0 };
                (new_state, new_cluster_index, new_payload_index, new_got_eos, state.5)
            },
            u32: 2 => {
                let new_cluster_index = u32: 0;
                let new_payload_index = u30: 0;
                let new_got_eos = zero!<u1[NUM_CLUSTERS]>();
                let new_state = u32: 0;
                (new_state, new_cluster_index, new_payload_index, new_got_eos, state.5)
            },
            _ => {(state.0, state.1, state.2, state.3, state.5)}
        };
        (st0, st1, st2, st3, new_tok, st5)
    }
}