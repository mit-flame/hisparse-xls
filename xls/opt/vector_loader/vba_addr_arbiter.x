import vector_helper;

pub proc vba_addr_arbiter {

    loading_addr:                          chan<vector_helper::StreamAddr> in;
    streaming_addr:                         chan<vector_helper::StreamAddr> in;
    unified_addr:                           chan<vector_helper::StreamAddr> out;


    config(
        loading_addr:                          chan<vector_helper::StreamAddr> in,
        streaming_addr:                         chan<vector_helper::StreamAddr> in,
        unified_addr:                           chan<vector_helper::StreamAddr> out
    ) {
        (
            loading_addr,
            streaming_addr,
            unified_addr
        )
    }

    init {token()}

    next (tok: token){
        let (t1, lpld, lvld) = recv_non_blocking(tok, loading_addr, zero!<vector_helper::StreamAddr>());
        let (t2, spld, svld) = recv_non_blocking(tok, streaming_addr, zero!<vector_helper::StreamAddr>());
        let o_pld = if (lvld) { lpld } else { spld };
        let t = join(t1, t2);
        (send_if(t, unified_addr, lvld || svld, o_pld))
    }

}