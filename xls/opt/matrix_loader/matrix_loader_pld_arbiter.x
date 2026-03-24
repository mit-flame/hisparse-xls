import matrix_helper;

pub proc matrix_loader_pld_arbiter<NUM_STREAMS: u32> {

    unified_pld:                           chan<matrix_helper::StreamPayload<NUM_STREAMS>> in;
    metadata_pld:                          chan<matrix_helper::StreamPayload<NUM_STREAMS>> out;
    streaming_pld:                         chan<matrix_helper::StreamPayload<NUM_STREAMS>> out;


    config(
        unified_pld:                           chan<matrix_helper::StreamPayload<NUM_STREAMS>> in,
        metadata_pld:                          chan<matrix_helper::StreamPayload<NUM_STREAMS>> out,
        streaming_pld:                         chan<matrix_helper::StreamPayload<NUM_STREAMS>> out
    ) {
        (
            unified_pld,
            metadata_pld,
            streaming_pld
        )
    }

    init {token()}

    next(tok: token){
        let (t1, upld) = recv(tok, unified_pld);
        let t2 = send_if(t1, metadata_pld, upld.message_type == u30: 0, upld);
        let t3 = send_if(t1, streaming_pld, upld.message_type == u30: 1, upld);
        (join(t2, t3))
    }

}