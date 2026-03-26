import pe_helper;

pub proc pe_recv<NUM_STREAMS: u32, QUEUE_DEPTH: u32>
{
    stream_id:                      chan<u32> in;
    unified_pld:                    chan<pe_helper::StreamPayload> in;
    accumulation_addr:              chan<pe_helper::StreamAddr> out;
    payload_type_four:              chan<uN[64]> out;

    config(
        stream_id:                      chan<u32> in,
        unified_pld:                    chan<pe_helper::StreamPayload> in,
        accumulation_addr:              chan<pe_helper::StreamAddr> out,
        payload_type_four:              chan<uN[64]> out
    ) {
        (
            stream_id, unified_pld, accumulation_addr, payload_type_four
        )
    }

    init{(
        u32: 0,                         // 0 state
        u32: 0,                         // 1 stream id
        zero!<uN[64][QUEUE_DEPTH]>(),   // 2 in flight write queue
        join(),                         // 3 ordering token
        false                           // 4 seen SOD
    )}

    next(state: (u32, u32, uN[64][QUEUE_DEPTH], token, bool)) {

        let new_state = 
        match (state.0) {
            u32: 0 => {
                let (new_tok, new_sid) = recv(state.3, stream_id);
                let new_state = u32: 1;
                let new_queue = zero!<uN[64][QUEUE_DEPTH]>();
                let new_seen_sod = false;
                (new_state, new_sid, new_queue, new_tok, new_seen_sod)
            },
            u32: 1 => {
                let (new_tok, spld) = recv(state.3, unified_pld);
                let base = pe_helper::priority_grab<QUEUE_DEPTH>(state.2, spld.addr, spld.mem_base);
                let incr = ((spld.matrix_val as s32) * (spld.vector_val as s32));
                let update = (spld.matrix_val != u32: 0) as u2 ++ spld.addr ++ ((base as s32) + incr) as u32;
                let new_queue = pe_helper::push_front<QUEUE_DEPTH>(state.2, update);
                let update_pld = pe_helper::StreamAddr{read_or_write: u1: 1, addr: spld.addr as u29, write_pld: update[0+:u32], ..zero!<pe_helper::StreamAddr>()};
                let result_indx = ((spld.addr * (NUM_STREAMS as u30)) + (state.1 as u30));
                let stream_pld = spld.commands ++ result_indx ++ spld.mem_base;
                let new_seen_sod = if (spld.commands == u2: 1) { true } else { state.4 };
                let accumulate = spld.commands == u2: 0 && !state.4;
                let new_tok = send_if(new_tok, accumulation_addr, accumulate, update_pld);
                let new_tok = send_if(new_tok, payload_type_four, !accumulate, stream_pld);
                let new_state = if (spld.commands == u2: 3) { u32: 0 } else { state.0 };
                (
                    new_state, state.1, new_queue, new_tok, new_seen_sod
                )
            },
            _ => {(state)}
        };
        (new_state)
    }
}