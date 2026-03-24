import matrix_helper;

pub proc matrix_loader_addr_arbiter {

    metadata_addr:                          chan<matrix_helper::StreamAddr> in;
    streaming_addr:                         chan<matrix_helper::StreamAddr> in;
    unified_addr:                           chan<matrix_helper::StreamAddr> out;


    config(
        metadata_addr:                          chan<matrix_helper::StreamAddr> in,
        streaming_addr:                         chan<matrix_helper::StreamAddr> in,
        unified_addr:                           chan<matrix_helper::StreamAddr> out
    ) {
        (
            metadata_addr,
            streaming_addr,
            unified_addr
        )
    }

    init {token()}

    next (tok: token){
        let (t1, mpld, mvld) = recv_non_blocking(tok, metadata_addr, zero!<matrix_helper::StreamAddr>());
        let (t2, spld, svld) = recv_non_blocking(tok, streaming_addr, zero!<matrix_helper::StreamAddr>());
        let o_pld = if (mvld) { mpld } else { spld };
        let t = join(t1, t2);
        (send_if(t, unified_addr, mvld || svld, o_pld))
    }

}