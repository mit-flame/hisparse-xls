import vector_helper;

pub proc vector_unpacker<
    NUM_STREAMS: u32,
    PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}
>{
    vector_payload_one:                 chan<uN[PAYLOAD_ONE_BITWIDTH]>  in;
    multistream_vector_payload_two:     chan<uN[64]>[NUM_STREAMS]      out;

    config(
        vector_payload_one:                 chan<uN[PAYLOAD_ONE_BITWIDTH]>  in,
        multistream_vector_payload_two:     chan<uN[64]>[NUM_STREAMS]      out
    ){
        (vector_payload_one, multistream_vector_payload_two)
    }

    init{(
        join()          // literally passthrough module, just needs to be a proc
                        // to interface with external procs while being standalone
                        // (since there is 1 unpacker for all NUM_STREAM VAUs)
    )}

    next(order_token: token){
        let (new_tok, payload_one) = recv(order_token, vector_payload_one);
        let new_tok =
        for (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
            let n_tok = send(tok, multistream_vector_payload_two[idx], vector_helper::payload_extractor<NUM_STREAMS>(payload_one, idx));
            (n_tok)
        }(new_tok);
        (new_tok)
    }
}


// 4 stream example
#[test_proc]
proc Tester {
    terminator: chan<bool> out;

    vector_payload_one:                 chan<uN[160]> out;
    multistream_vector_payload_two:     chan<uN[64]>[4]       in;

    config(
        terminator: chan<bool> out
    ){
        let (vpoo, vpoi) = chan<uN[160]>("vpo");
        let (mvpto, mvpti) = chan<uN[64]>[4]("mvpt");
        spawn vector_unpacker<u32: 4>(vpoi, mvpto);
        (
            terminator,
            vpoo, mvpti
        )
    }

    init {()}

    next (tester_state: ()) {
        let tok = send(join(), vector_payload_one, u2: 0 ++ u30: 10 ++ u32: 3 ++ u32: 2 ++ u32: 1 ++ u32: 0);
        let tok =
        for (idx, tok) : (u32, token) in u32:0..u32:4{
            let (n_tok, pld) = recv(tok, multistream_vector_payload_two[idx]);
            trace_fmt!("received {:0x}", pld);
            (n_tok)
        }(tok);
        send(tok, terminator, true);
    }
}