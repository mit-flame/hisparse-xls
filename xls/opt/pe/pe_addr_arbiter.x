// only the pe_send needs an addr arbiter, bank memory must be dual port anyway so the pe_recv has its own port to itself
import pe_helper;

pub proc pe_addr_arbiter{

    clearing_addr:                  chan<pe_helper::StreamAddr> in;
    streaming_addr:                 chan<pe_helper::StreamAddr> in;
    result_addr:                    chan<pe_helper::StreamAddr> in;
    unified_addr:                   chan<pe_helper::StreamAddr> out;


    config(
        clearing_addr:                  chan<pe_helper::StreamAddr> in,
        streaming_addr:                 chan<pe_helper::StreamAddr> in,
        result_addr:                    chan<pe_helper::StreamAddr> in,
        unified_addr:                   chan<pe_helper::StreamAddr> out
    ) {
        (
            clearing_addr, streaming_addr, result_addr, unified_addr
        )
    }

    init {token()}

    next (tok: token){
        let (t1, cpld, cvld) = recv_non_blocking(tok, clearing_addr, zero!<pe_helper::StreamAddr>());
        let (t2, spld, svld) = recv_non_blocking(tok, streaming_addr, zero!<pe_helper::StreamAddr>());
        let (t3, rpld, rvld) = recv_non_blocking(tok, result_addr, zero!<pe_helper::StreamAddr>());
        let o_pld = if (cvld) { cpld } else if (svld) { spld } else { rpld };
        let t = join(t1, t2, t3);
        (send_if(t, unified_addr, cvld || svld || rvld, o_pld))
    }

}