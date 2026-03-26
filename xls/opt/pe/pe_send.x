import pe_helper;

pub proc pe_send<NUM_STREAMS: u32>
{
    num_rows_updated:               chan<u30> in;
    payload_type_three:             chan<uN[96]>  in;
    clearing_addr:                  chan<pe_helper::StreamAddr> out;
    streaming_addr:                 chan<pe_helper::StreamAddr> out;
    result_addr:                    chan<pe_helper::StreamAddr> out;

    config(
        num_rows_updated:               chan<u30> in,
        payload_type_three:             chan<uN[96]>  in,
        clearing_addr:                  chan<pe_helper::StreamAddr> out,
        streaming_addr:                 chan<pe_helper::StreamAddr> out,
        result_addr:                    chan<pe_helper::StreamAddr> out
    ) {
        (
            num_rows_updated, payload_type_three, clearing_addr, streaming_addr, result_addr
        )
    }

    init{(
        u32: 0,                         // 0 state
        u30: 0,                         // 1 num rows updated AKA max index into the output buffer
        u30: 0,                         // 2 bank index (for clearing it and writing out)
        join(),                         // 3 ordering token
        false,                          // 4 seen SOD for streaming
        false,                          // 5 sent SOD for write out
        false                           // 6 sent EOD for write out
    )}

    next(state: (u32, u30, u30, token, bool, bool, bool)) {

        let new_state = 
        match (state.0) {
            u32: 0 => {
                let (new_tok, new_num_rows) = recv(state.3, num_rows_updated);
                let new_state = u32: 1;
                let new_bank_index = u30: 0;
                let new_seen_sod_streaming = false;
                let new_sent_sod_write_out = false;
                let new_sent_eod_write_out = false;
                (
                    new_state, new_num_rows, new_bank_index, new_tok, new_seen_sod_streaming, new_sent_sod_write_out, new_sent_eod_write_out
                )
            },
            u32: 1 => {
                let new_tok = send(state.3, clearing_addr, pe_helper::StreamAddr{read_or_write: u1: 1, addr: state.2 as u29, write_pld: u32: 0, ..zero!<pe_helper::StreamAddr>()});
                let new_bank_index = state.2 + u30: 1;
                let finished_clear_predicate = new_bank_index == state.1;
                let new_state = if (finished_clear_predicate) { u32: 2 } else { state.0 };
                (
                    new_state, state.1, new_bank_index, new_tok, state.4, state.5, state.6
                )
            },
            u32: 2 => {
                let (new_tok, payload_three) = recv(state.3, payload_type_three);
                let new_seen_sod = if (payload_three[94+:u2] == u2: 2) { false } else if (payload_three[94+:u2] == u2: 1) { true } else { state.4 };
                let new_state = if (payload_three[94+:u2] == u2: 3) { u32: 3 } else { state.0 };
                let new_bank_index = u30: 0;
                let bank_addr = payload_three[64+:u30] / (NUM_STREAMS as u30);
                let new_tok = send_if(new_tok, streaming_addr, state.4 && payload_three[0+:u32] != u32: 0, pe_helper::StreamAddr{read_or_write: u1: 0, addr: bank_addr as u29, matrix_val: payload_three[0+:u32], vector_val: payload_three[32+:u32], ..zero!<pe_helper::StreamAddr>()});
                (
                    new_state, state.1, new_bank_index, new_tok, new_seen_sod, state.5, state.6
                )
            },
            u32: 3 => {
                let opld = 
                if (!state.5) { pe_helper::StreamAddr{read_or_write: u1: 0, commands: u2: 1, ..zero!<pe_helper::StreamAddr>()} }
                else if (state.2 < state.1) { pe_helper::StreamAddr{read_or_write: u1: 0, addr: state.2 as u29, ..zero!<pe_helper::StreamAddr>()} }
                else if (!state.6) { pe_helper::StreamAddr{read_or_write: u1: 0, commands: u2: 2, ..zero!<pe_helper::StreamAddr>()} }
                else { pe_helper::StreamAddr{read_or_write: u1: 0, commands: u2: 3, ..zero!<pe_helper::StreamAddr>()} };
                let new_tok = send(state.3, result_addr, opld);
                let new_sent_sod = if (!state.5) { true } else { state.5 };
                let new_sent_eod = if (!state.6 && state.2 >= state.1) { true } else { state.6 };
                let new_state = if (state.6) { u32: 0 } else { state.0 };
                let new_bank_index = if (!state.5) { state.2 } else { state.2 + u30: 1};
                (
                    new_state, state.1, new_bank_index, new_tok, state.4, new_sent_sod, new_sent_eod
                )
            },
            _ => {(state)}
        };
        (new_state)
    }
}