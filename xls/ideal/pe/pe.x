import pe_helper;

pub proc processing_engine<
    NUM_STREAMS: u32,
    BANK_SIZE: u32,
    QUEUE_DEPTH: u32
>{
    payload_type_three:             chan<uN[96]>  in;
    vecbuf_bank_addr:               chan<u32> out;
    vecbuf_bank_din:               chan<u32>  in;
    vecbuf_bank_dout:              chan<u32> out;
    num_rows_updated:               chan<u30> in; // if a pe does row 0, 4, 8, then this is 3 for 3 rows updated
    stream_id:                      chan<u32> in; // this is required to reconstruct the true vector index of the output

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
        join()                          // 5 ordering token
    )}

    next(state: (u32, u32, u30, u30, uN[64][QUEUE_DEPTH], token)) {


        // trace_fmt!(" ");
        // trace_fmt!(" current state ");
        // trace_fmt!("---------------");
        // trace_fmt!("state  : {:0x}", state.0);
        // trace_fmt!("strmid : {:0x}", state.1);
        // trace_fmt!("nmrowup: {:0x}", state.2);
        // trace_fmt!("bnkindx: {:0x}", state.3);
        // trace_fmt!("ifwq   : {:0x}", state.4);
        // trace_fmt!("---------------");
        // trace_fmt!(" ");
        // trace_fmt!(" ");


        let new_state =
        // init state. save the used buffer length and stream id, reset bank index
        if (state.0 == u32: 0){
            let (tok1, new_num_rows) = recv(state.5, num_rows_updated);
            let (tok2, new_stream_id) = recv(state.5, stream_id);
            let new_tok = join(tok1, tok2);
            let new_state = u32: 1;
            let new_bank_index = u30: 0;
            (
                new_state, new_stream_id, new_num_rows, new_bank_index, state.4, new_tok
            )
        }
        else
        // clear banks original contents
        if (state.0 == u32: 1){
            let new_tok = send(state.5, vecbuf_bank_addr, u2:1 ++ state.3);
            let new_tok = send(new_tok, vecbuf_bank_dout, u32: 0);
            let new_bank_index = state.3 + u30: 1;
            let finished_clear_predicate = new_bank_index == state.2;
            let new_state = if (finished_clear_predicate) { u32: 2 } else { state.0 };
            (
                new_state, state.1, state.2, new_bank_index, state.4, new_tok
            )
        }
        else
        // sync on SOD or EOS, clear in flight write queue, resent bank index
        // if EOS send SOD before transition
        if (state.0 == u32: 2){
            let (new_tok, payload_three) = recv(state.5, payload_type_three);
            let got_sod = payload_three[94+:u2] == u2: 1;
            let got_eos = payload_three[94+:u2] == u2: 3;
            let new_state = 
            if (got_sod) { u32: 3 }
            else if (got_eos) { u32: 4 }
            else { state.0 };
            let new_queue = zero!<uN[64][QUEUE_DEPTH]>();
            let new_bank_index = u30: 0;
            let new_tok = send_if(new_tok, payload_type_four, got_eos, u2: 1 ++ uN[62]:0);
            (
                new_state, state.1, state.2, new_bank_index, new_queue, new_tok
            )
        }
        else
        // accumulation and in flight write queue updates
        // exit upon EOD
        if (state.0 == u32: 3){
            let (new_tok, payload_three) = recv(state.5, payload_type_three);
            let got_eod = payload_three[94+:u2] == u2: 2; // got_eod will imply not valid since payload is all zeros
            let valid = payload_three[0+:u32] != u32: 0;
            let bank_addr = payload_three[64+:u30] / (NUM_STREAMS as u30);
            let new_tok = send_if(new_tok, vecbuf_bank_addr, valid, u2: 2 ++ bank_addr); // u2: 2 is a read req
            let (new_tok, mem_base) = recv_if(new_tok, vecbuf_bank_din, valid, u32: 0);
            let base = pe_helper::priority_grab<QUEUE_DEPTH>(state.4, bank_addr, mem_base);
            let incr = (payload_three[0+:s32] * payload_three[32+:s32]);
            let update = valid as u2 ++ bank_addr ++ ((base as s32) + incr) as u32;
            let new_queue = pe_helper::push_front<QUEUE_DEPTH>(state.4, update);
            let new_tok = send_if(new_tok, vecbuf_bank_addr, valid, u2: 1 ++ bank_addr);
            let new_tok = send_if(new_tok, vecbuf_bank_dout, valid, update[0+:u32]);
            let new_state = if (got_eod) { u32: 2 } else { state.0 };
            (
                new_state, state.1, state.2, state.3, new_queue, new_tok
            )
        }
        else
        // stream bank results to the output until hit used buf length
        if (state.0 == u32: 4){
            let new_tok = send(state.5, vecbuf_bank_addr, u2: 2 ++ state.3);
            let (new_tok, result) = recv(new_tok, vecbuf_bank_din);
            let result_indx = ((state.3 * (NUM_STREAMS as u30)) + (state.1 as u30));
            let new_tok = send(new_tok, payload_type_four, result_indx as u32 ++ result);
            let new_bank_index = state.3 + u30: 1;
            let finished_stream_predicate = new_bank_index == state.2;
            let new_state = if (finished_stream_predicate) { u32: 5 } else { state.0 };
            (
                new_state, state.1, state.2, new_bank_index, state.4, new_tok
            )
        }
        else
        // send EOD and EOS, go back to state 0
        if (state.0 == u32: 5) {
            let new_tok = send(state.5, payload_type_four, u2: 2 ++ uN[62]:0);
            let new_tok = send(new_tok, payload_type_four, u2: 3 ++ uN[62]:0);
            let new_state = u32: 0;
            (
                new_state, state.1, state.2, state.3, state.4, new_tok
            )
        }
        else
        {
            trace_fmt!("SHOULD NOT BE IN THIS STATE!!!!");
            state
        };
        new_state
    }
}