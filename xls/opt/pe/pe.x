import pe_helper;

pub proc processing_engine<NUM_STREAMS: u32, BANK_SIZE: u32, QUEUE_DEPTH: u32>
{
    payload_type_three:             chan<uN[96]>  in;
    vecbuf_bank_addr:               chan<u32> out;
    vecbuf_bank_din:               chan<u32>  in;
    vecbuf_bank_dout:              chan<u32> out;
    num_rows_updated:               chan<u30> in;
    stream_id:                      chan<u32> in;

    payload_type_four:              chan<uN[64]> out;

    config(
        payload_type_three:             chan<uN[96]>  in,
        vecbuf_bank_addr:               chan<u32> out,
        vecbuf_bank_din:               chan<u32>  in,
        vecbuf_bank_dout:              chan<u32> out,
        num_rows_updated:               chan<u30> in,
        stream_id:                      chan<u32> in,
        payload_type_four:              chan<uN[64]> out
    ) {
        (
            payload_type_three, vecbuf_bank_addr, vecbuf_bank_din, vecbuf_bank_dout, num_rows_updated, stream_id, payload_type_four
        )
    }

    init{(
        u32: 0,                         // 0 state
        u32: 0,                         // 1 stream id
        u30: 0,                         // 2 num rows updated AKA max index into the output buffer
        u30: 0,                         // 3 bank index (for clearing it and writing out)
        zero!<uN[64][QUEUE_DEPTH]>(),   // 4 in flight write queue
        join(),                         // 5 ordering token
        // non original proc state
        uN[96]: 0,                      // 6 payload type three latch
        u32: 0                          // 7 din latch
    )}

    next(state: (u32, u32, u30, u30, uN[64][QUEUE_DEPTH], token, uN[96], u32)) {

        let (vba_tx, vbd_tx, ptf_tx, ptt_rx, vbd_rx, nru_rx, si_rx) =
        match (state.0) {
            u32: 0 => {(false, false, false, false, false, true, true)},
            u32: 1 => {(true, true, false, false, false, false, false)},
            u32: 2 => {(false, false, false, true, false, false, false)},
            u32: 30 => {(false, false, false, true, false, false, false)},
            u32: 31 => {
                let valid = state.6[0+:u32] != u32: 0;
                (valid, false, false, false, false, false, false)
            },
            u32: 32 => {
                let valid = state.6[0+:u32] != u32: 0;
                (false, false, false, false, valid, false, false)
            },
            u32: 33 => {
                let valid = state.6[0+:u32] != u32: 0;
                (valid, valid, false, false, false, false, false)
            },
            u32: 40 => {(false, false, true, false, false, false, false)},
            u32: 41 => {(true, false, false, false, false, false, false)},
            u32: 42 => {(false, false, false, false, true, false, false)},
            u32: 43 => {(false, false, true, false, false, false, false)},
            u32: 50 => {(false, false, true, false, false, false, false)},
            u32: 51 => {(false, false, true, false, false, false, false)},
            _ => {(false, false, false, false, false, false, false)}
        };

        let (vba_pld, vbd_pld, ptf_pld) =
        match (state.0) {
            u32: 1 => {
                (u2:1 ++ state.3, u32: 0, uN[64]: 0)
            },
            u32: 31 => {
                let bank_addr = state.6[64+:u30] / (NUM_STREAMS as u30);
                let vba_pld = u2: 2 ++ bank_addr;
                (vba_pld, u32: 0, uN[64]: 0)
            },
            u32: 33 => {
                let valid = state.6[0+:u32] != u32: 0;
                let bank_addr = state.6[64+:u30] / (NUM_STREAMS as u30);
                let base = pe_helper::priority_grab<QUEUE_DEPTH>(state.4, bank_addr, state.7);
                let incr = (state.6[0+:s32] * state.6[32+:s32]);
                let update = valid as u2 ++ bank_addr ++ ((base as s32) + incr) as u32;
                let vba_pld = u2: 1 ++ bank_addr;
                let vbd_pld = update[0+:u32];
                (vba_pld, vbd_pld, uN[64]: 0)
            },
            u32: 40 => {
                let ptf_pld = u2: 1 ++ uN[62]:0;
                (u32: 0, u32: 0, ptf_pld)
            },
            u32: 41 => {
                let vba_pld = u2: 2 ++ state.3;
                (vba_pld, u32: 0, uN[64]: 0)
            },
            u32: 43 => {
                let result_indx = ((state.3 * (NUM_STREAMS as u30)) + (state.1 as u30));
                let ptf_pld = result_indx as u32 ++ state.7;
                (u32: 0, u32: 0, ptf_pld)
            },
            u32: 50 => {
                let ptf_pld = u2: 2 ++ uN[62]:0;
                (u32: 0, u32: 0, ptf_pld)
            },
            u32: 51 => {
                let ptf_pld = u2: 3 ++ uN[62]:0;
                (u32: 0, u32: 0, ptf_pld)
            },
            _ => {(u32: 0, u32: 0, uN[64]: 0)}
        };

        // trace_fmt!("---------------");
        // trace_fmt!("state  : {:0x}", state.0);
        // trace_fmt!("strmid : {:0x}", state.1);
        // trace_fmt!("nmrowup: {:0x}", state.2);
        // trace_fmt!("bnkindx: {:0x}", state.3);
        // trace_fmt!("ifwq   : {:0x}", state.4);
        // trace_fmt!("{:0x} sends {:0x} {:0x} {:0x} ", state.1, vba_pld, vbd_pld, ptf_pld);
        // trace_fmt!("bools {:0x} {:0x} {:0x} {:0x} {:0x} {:0x} {:0x} ", vba_tx, vbd_tx, ptf_tx, ptt_rx, vbd_rx, nru_rx, si_rx);

        let t1 = send_if(state.5, vecbuf_bank_addr, vba_tx, vba_pld);
        let t2 = send_if(state.5, vecbuf_bank_dout, vbd_tx, vbd_pld);
        let t3 = send_if(state.5, payload_type_four, ptf_tx, ptf_pld);
        let (t4, ptt_pld) = recv_if(state.5, payload_type_three, ptt_rx, uN[96]: 0);
        let (t5, vbdin_pld) = recv_if(state.5, vecbuf_bank_din, vbd_rx, u32: 0);
        let (t6, nru_pld) = recv_if(state.5, num_rows_updated, nru_rx, u30: 0);
        let (t7, si_pld) = recv_if(state.5, stream_id, si_rx, u32: 0);
        let new_tok = join(t1, t2, t3, t4, t5, t6, t7);


        // trace_fmt!("{:0x} recvs {:0x} {:0x} {:0x} {:0x}", state.1, ptt_pld, vbdin_pld, nru_pld, si_pld);
        // trace_fmt!("---------------");

        let (st0, st1, st2, st3, st4, st6, st7) =
        match (state.0) {
            u32: 0 => {
                let new_state = u32: 1;
                let new_bank_index = u30: 0;
                (
                    new_state, si_pld, nru_pld, new_bank_index, state.4, state.6, state.7
                )
            },
            u32: 1 => {
                let new_bank_index = state.3 + u30: 1;
                let finished_clear_predicate = new_bank_index == state.2;
                let new_state = if (finished_clear_predicate) { u32: 2 } else { state.0 };
                (
                    new_state, state.1, state.2, new_bank_index, state.4, state.6, state.7
                )
            },
            u32: 2 => {
                let got_sod = ptt_pld[94+:u2] == u2: 1;
                let got_eos = ptt_pld[94+:u2] == u2: 3;
                let new_state = if (got_sod) { u32: 30 } else if (got_eos) { u32: 40 } else { state.0 };
                let new_queue = zero!<uN[64][QUEUE_DEPTH]>();
                let new_bank_index = u30: 0;
                (
                    new_state, state.1, state.2, new_bank_index, new_queue, state.6, state.7
                )
            },
            u32: 30 => {
                let new_state = u32: 31;
                (new_state, state.1, state.2, state.3, state.4, ptt_pld, state.7)
            },
            u32: 31 => {
                let new_state = u32: 32;
                (new_state, state.1, state.2, state.3, state.4, state.6, state.7)
            },
            u32: 32 => {
                let new_state = u32: 33;
                (new_state, state.1, state.2, state.3, state.4, state.6, vbdin_pld)
            },
            u32: 33 => { 
                let got_eod = state.6[94+:u2] == u2: 2;
                let new_state = if (got_eod) { u32: 2 } else { u32: 30 };
                (new_state, state.1, state.2, state.3, state.4, state.6, state.7)
            },
            u32: 40 => {
                let new_state = u32: 41;
                (new_state, state.1, state.2, state.3, state.4, state.6, state.7)
            },
            u32: 41 => {
                let new_state = u32: 42;
                (new_state, state.1, state.2, state.3, state.4, state.6, state.7)
            },
            u32: 42 => {
                let new_state = u32: 43;
                (new_state, state.1, state.2, state.3, state.4, state.6, vbdin_pld)
            },
            u32: 43 => {
                let new_bank_index = state.3 + u30: 1;
                let finished_stream_predicate = new_bank_index == state.2;
                let new_state = if (finished_stream_predicate) { u32: 50 } else { u32: 41 };
                (new_state, state.1, state.2, new_bank_index, state.4, state.6, state.7)
            },
            u32: 50 => {
                let new_state = u32: 51;
                (new_state, state.1, state.2, state.3, state.4, state.6, state.7)
            },
            u32: 51 => {
                let new_state = u32: 0;
                (new_state, state.1, state.2, state.3, state.4, state.6, state.7)
            },
            _ => {(state.0, state.1, state.2, state.3, state.4, state.6, state.7)}
        };

        (st0, st1, st2, st3, st4, new_tok, st6, st7)
    }
}