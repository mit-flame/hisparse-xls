import vector_helper;

pub proc vba_send<BANK_SIZE: u32,NUM_STREAMS: u32>
{
    matrix_payload_two:         chan<uN[96]>              in;
    vector_payload_two:         chan<uN[64]>              in;
    num_col_partitions:         chan<u32>                 in;

    loading_addr:               chan<vector_helper::StreamAddr> out;
    streaming_addr:             chan<vector_helper::StreamAddr> out;

    config(
    matrix_payload_two:         chan<uN[96]>              in,
    vector_payload_two:         chan<uN[64]>              in,
    num_col_partitions:         chan<u32>                 in,

    loading_addr:               chan<vector_helper::StreamAddr> out,
    streaming_addr:             chan<vector_helper::StreamAddr> out 
    ) {
        (
            matrix_payload_two, vector_payload_two, num_col_partitions,
            loading_addr, streaming_addr
        )
    }

    init {(
        u32: 0,                      // 0 state
        u32: 0,                      // 1 num COLUMN partitions
        u32: 0,                      // 2 current partition
        join(),                      // 3 order token
        false,                       // 4 got SOD for vector payload
        false                        // 5 got SOD for matrix payload
    )}

    next(state: (u32, u32, u32, token, bool, bool)) {
        let new_state =
        match (state.0) {
            u32: 0 => {
                let (new_tok, new_num_col_partitions) = recv(state.3, num_col_partitions);
                let new_cur_part = u32: 0;
                let new_vec_sod = false;
                let new_mtx_sod = false;
                let new_state = u32: 1;
                (
                    new_state, new_num_col_partitions, new_cur_part, new_tok, new_vec_sod, new_mtx_sod
                )
            },
            // SOD/EOS sync /w vector_loader, load vector loader into bank until EOD
            u32: 1 => {
                let (new_tok, vector_payload) = recv(state.3, vector_payload_two);
                let (cmd, indx, data) = vector_helper::unpack_payload_two(vector_payload);
                let new_state = if (cmd == u2: 2 || cmd == u2: 3) { u32: 2 } else { state.0 };
                let new_vec_sod = if (cmd == u2: 1) { true } else { state.4 };
                let buf_addr = ((indx as u32) / NUM_STREAMS) % BANK_SIZE;
                let loading_pld = vector_helper::StreamAddr{read_or_write: u1: 1, addr: buf_addr as u29, write_pld: data, ..zero!<vector_helper::StreamAddr>()};
                let new_tok = send_if(new_tok, loading_addr, (cmd != u2: 2) && (cmd != u2: 1) && state.4, loading_pld);
                (
                    new_state, state.1, state.2, new_tok, new_vec_sod, state.5
                )
            },
            // SOD/EOS sync /w matrix loader, stream reads until EOD
            u32: 2 => {
                let (new_tok, matrix_payload) = recv(state.3, matrix_payload_two);
                let (cmd, col_indx, row_indx, data) = vector_helper::unpack_matrix_payload_two(matrix_payload);
                let new_state = if (cmd == u2: 2 || cmd == u2: 3) { u32: 3 } else { state.0 };
                let new_mtx_sod = if (cmd == u2: 1) { true } else { state.5 };
                let bank_addr = ((col_indx as u32) / NUM_STREAMS) % BANK_SIZE;
                let streaming_pld = vector_helper::StreamAddr{read_or_write: u1: 0, commands: cmd, addr: bank_addr as u29, matrix_pld: data, row_indx: row_indx, ..zero!<vector_helper::StreamAddr>()};
                let new_tok = send_if(new_tok, streaming_addr, (cmd != u2: 0) || (matrix_payload != uN[96]: 0 && state.5), streaming_pld);
                (
                    new_state, state.1, state.2, new_tok, state.4, new_mtx_sod
                )
            },
            u32: 3 => {
                let new_cur_part = state.2 + u32: 1;
                let new_state = if (new_cur_part < (state.1 + u32: 1)) { u32: 1 } else { u32: 0 };
                let new_vec_sod = false;
                let new_mtx_sod = false;
                (
                    new_state, state.1, new_cur_part, state.3, new_vec_sod, new_mtx_sod
                )
            },
            _ => { (state) }
        };
        (new_state)
    }
}