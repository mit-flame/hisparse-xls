import arbiter_helper;

pub proc arbiter_wrapper<NUM_STREAMS: u32>{
    payload:                    chan<uN[96][NUM_STREAMS]> in; // notice that this isnt a parametric channel, instead only accepting a single value
                                                              // shuffler core will create the single all-stream value from sampling each stream
    i_valid:                    chan<u1[NUM_STREAMS]> in;
    rotate_offset:              chan<u32>             in;

    combined_out:               chan<arbiter_helper::ArbOut<NUM_STREAMS>> out;

    config(
        payload:         chan<uN[96][NUM_STREAMS]> in,
        i_valid:                    chan<u1[NUM_STREAMS]> in,
        rotate_offset:              chan<u32> in,

        // these should come N cycles later, where N is the pipeline depth
        // the arbiter func/this proc is synthesized with.
        combined_out: chan<arbiter_helper::ArbOut<NUM_STREAMS>> out
    ) {
        (
            payload, i_valid, rotate_offset, 
            combined_out
        )
    }

    // simply order the activations such that
    // arbiter inputs have arbiter outputs in order
    init {(join())}

    next (order_token: token) {
        // we get the inputs as soon as possible
        let (tok1, ptt) = recv(order_token, payload);
        let (tok2, iv) = recv(order_token, i_valid);
        let (tok3, ro) = recv(order_token, rotate_offset);
        let order_token = join(tok1, tok2, tok3);
        // compute arbiter result in N cycles
        let (rptt, rpv, xs, xv) = arbiter_helper::arbiter<NUM_STREAMS>(ptt, iv, ro);

        // pass through command payloads, assuming they are all synced so only look at first payload
        let cmd_payload_predicate = ptt[0][94+:u2] != u2: 0 && ptt[0][94+:u2] != u2: 2;
        let rpv = if (cmd_payload_predicate) { zero!<u1[NUM_STREAMS]>() } else { rpv };
        let xs =
        for (idx, nxs) : (u32, u32[NUM_STREAMS]) in u32:0..NUM_STREAMS {
            let n_nxs = if (cmd_payload_predicate) { update(nxs, idx, idx) } else { nxs };
            (n_nxs)
        }(xs);
        let xv = if (cmd_payload_predicate) { all_ones!<u1[NUM_STREAMS]>() } else { xv };
        let iv = if (cmd_payload_predicate) { all_ones!<u1[NUM_STREAMS]>() } else { iv };

        // ensure results are ordered using the order token
        let order_token = send(order_token, combined_out, arbiter_helper::ArbOut<NUM_STREAMS>{rptt: rptt, rpv: rpv, xs: xs, xv: xv, oiv: iv});
        (order_token)
    }
}
