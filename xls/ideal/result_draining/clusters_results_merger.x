// equivalent to axis_merge in the hisparse source stream_utils.h
pub proc clusters_results_merger<
    NUM_CLUSTERS: u32,
    NUM_STREAMS: u32,
    PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}

>{
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
        join()                          // 4 order token
    )}

    next (state: (u32, u32, u30, u1[NUM_CLUSTERS], token)) {
        let new_state = 
        // cyclical streaming
        if (state.0 == u32: 0){
            let (new_token, payload_one) = recv(state.4, multistream_vector_payload_one[state.1]);
            let new_cluster_index = ( state.1 + u32: 1 ) % NUM_CLUSTERS;
            let payload_index_incremented = ( state.2 + u30: 1 );
            let got_eos = payload_one[(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 3;
            let new_got_eos = if (got_eos) { update(state.3, state.1, got_eos) } else { state.3 };
            let new_payload_one = payload_one[(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] ++ state.2 ++ payload_one[:(NUM_STREAMS << u32: 5) as s32];
            // trace_fmt!("sending {:0x} {:0x}", got_eos, new_payload_one);
            let new_token = send_if(new_token, vector_payload_one, !got_eos, new_payload_one);
            let new_payload_index = if (payload_one[(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 0) { payload_index_incremented } else{ state.2 };
            let new_state = if (and_reduce(new_got_eos as uN[NUM_CLUSTERS])) { u32: 1 } else { state.0 };
            (
                new_state, new_cluster_index, new_payload_index, new_got_eos, new_token
            )
        }
        else
        // send EOS, reset values, go back to state 0
        if (state.0 == u32: 1){
            let eos_pld = zero!<uN[(NUM_STREAMS << u32: 5)]>();
            let eos_indx = u30: 0;
            let eos_cmd = u2: 3;
            let pld = eos_cmd ++ eos_indx ++ eos_pld;
            let new_token = send(state.4, vector_payload_one, pld);
            let new_cluster_index = u32: 0;
            let new_payload_index = u30: 0;
            let new_got_eos = zero!<u1[NUM_CLUSTERS]>();
            let new_state = u32: 0;
            (
                new_state, new_cluster_index, new_payload_index, new_got_eos, new_token
            )
        }
        else {
            trace_fmt!("SHOULDNT BE HERE!!");
            state
        };
        new_state
    }
}