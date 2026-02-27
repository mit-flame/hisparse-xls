import vector_helper;

pub proc vecbuf_access_unit<BANK_SIZE: u32,NUM_STREAMS: u32>
{
    matrix_payload_two:         chan<uN[96]>              in;
    vector_payload_two:         chan<uN[64]>              in;
    num_col_partitions:         chan<u32>                 in;

    vecbuf_bank_addr:       chan<u32>                out;
    vecbuf_dout:            chan<u32>                out;
    vecbuf_din:             chan<u32>                 in;

    payload_type_three:         chan<uN[96]> out;

    config(
        matrix_payload_two:         chan<uN[96]>  in,
        vector_payload_two:         chan<uN[64]>  in,
        num_col_partitions:         chan<u32>     in,
        vecbuf_bank_addr:       chan<u32>                out,
        vecbuf_dout:            chan<u32>                out,
        vecbuf_din:             chan<u32>                 in,
        payload_type_three:         chan<uN[96]> out
    ) {
        (
            matrix_payload_two, vector_payload_two, num_col_partitions,
            vecbuf_bank_addr,vecbuf_dout,vecbuf_din,
            payload_type_three
        )
    }

    init {(
        u32: 0,                      // 0 state
        u32: 0,                      // 1 num COLUMN partitions
        u32: 0,                      // 2 current partition
        join(),                      // 3 order token
        // substate
        uN[64]: 0,                      // 4 latched vector payload
        uN[96]: 0,                      // 5 latched matrix payload
        u32: 0                          // 6 latched vecbuf_din payload
    )}

    next(state: (u32, u32, u32, token, uN[64], uN[96], u32)) {

        // trace_fmt!(" ");
        // trace_fmt!(" current state ");
        // trace_fmt!("---------------");
        // trace_fmt!("state  : {:0x}", state.0);
        // trace_fmt!("numcolp: {:0x}", state.1);
        // trace_fmt!("curcolp: {:0x}", state.2);
        // trace_fmt!("---------------");
        // trace_fmt!(" ");
        // trace_fmt!(" ");

        let (vba_tx, vd_tx, ptt_tx, mpt_rx, vpt_rx, ncp_rx, vd_rx) =
        match (state.0) {
            u32: 0 => {(false, false, false, false, false, true, false)},
            u32: 1 => {(false, false, false, false, true, false, false)},
            u32: 20 => {(false, false, false, false, true, false, false)},
            u32: 21 => {
                let (cmd, _, _) = vector_helper::unpack_payload_two(state.4);
                let got_eod = cmd == u2:2;
                (!got_eod, !got_eod, false, false, false, false, false)
            },
            u32: 30 => {(false, false, false, true, false, false, false)},
            u32: 31 => {
                let cmd = state.5[94+:u2];
                let got_sod = cmd == u2:1;
                let got_eos = cmd == u2:3;
                let send_pred = got_sod || got_eos;
                (false, false, send_pred, false, false, false, false)
            },
            u32: 40 => {(false, false, false, true, false, false, false)},
            u32: 41 => {
                let cmd = state.5[94+:u2];
                let got_eod = cmd == u2:2;
                let null_payload = state.5 == uN[96]:0;
                let request_bank_predicate = !(got_eod || null_payload);
                (request_bank_predicate, false, false, false, false, false, false)
            },
            u32: 42 => {
                let cmd = state.5[94+:u2];
                let got_eod = cmd == u2:2;
                let null_payload = state.5 == uN[96]:0;
                let request_bank_predicate = !(got_eod || null_payload);
                (false, false, false, false, false, false, request_bank_predicate)
            },
            u32: 43 => {(false, false, true, false, false, false, false)},
            u32: 5 => {(false, false, false, false, false, false, false)},
            _ => {(false, false, false, false, false, false, false)}
        };

        let (vba_pld, vd_pld, ptt_pld) =
        match (state.0){
            u32: 21 => {
                let (cmd, indx, data) = vector_helper::unpack_payload_two(state.4);
                let buf_addr = ((indx as u32) / NUM_STREAMS) % BANK_SIZE;
                // 1 is a write, 2 is a read, 0 and 3 is reserved
                (u2: 1 ++ (buf_addr as u30), data, uN[96]: 0)
            },
            u32: 31 => {
                let cmd = state.5[94+:u2];
                let got_sod = cmd == u2:1;
                let got_eos = cmd == u2:3;
                let ptt_pld = if (got_sod) { u2: 1 ++ zero!<uN[94]>() } else if (got_eos) { u2: 3 ++ zero!<uN[94]>() } else { uN[96] : 0 };
                (u32: 0, u32: 0, ptt_pld)
            },
            u32: 41 => {
                let (cmd, col_indx, row_indx, data) = vector_helper::unpack_matrix_payload_two(state.5);
                let bank_addr = ((col_indx as u32) / NUM_STREAMS) % BANK_SIZE;
                // read is u2: 2
                (u2: 2 ++ (bank_addr as u30), u32: 0, uN[96]: 0)
            },
            u32: 43 => {
                let cmd = state.5[94+:u2];
                let got_eod = cmd == u2:2;
                let null_payload = state.5 == uN[96]:0;
                let payload_three = 
                if (got_eod) 
                { u2: 2 ++ zero!<uN[94]>() } 
                else if (null_payload) // <----- fix to address failure to filter out null payloads
                { uN[96]: 0 }
                else 
                { vector_helper::matrix_vector_payload_merge(state.5,state.6) };
                (u32: 0, u32: 0, payload_three)
            },
            _ => {(u32: 0, u32: 0, uN[96]: 0)}
        };

        let t1 = send_if(state.3, vecbuf_bank_addr, vba_tx, vba_pld);
        let t2 = send_if(state.3, vecbuf_dout, vd_tx, vd_pld);
        let t3 = send_if(state.3, payload_type_three, ptt_tx, ptt_pld);
        let (t4, mpt_pld) = recv_if(state.3, matrix_payload_two, mpt_rx, uN[96]: 0);
        let (t5, vpt_pld) = recv_if(state.3, vector_payload_two, vpt_rx, uN[64]: 0);
        let (t6, ncp_pld) = recv_if(state.3, num_col_partitions, ncp_rx, u32: 0);
        let (t7, vd_pld) = recv_if(state.3, vecbuf_din, vd_rx, u32: 0);
        let new_tok = join(t1, t2, t3, t4, t5, t6, t7);

        let (st0, st1, st2, st4, st5, st6) =
        match (state.0) {
            u32: 0 => {
                let new_cur_part = u32: 0;
                let new_state = u32: 1;
                (new_state, ncp_pld, new_cur_part, state.4, state.5, state.6)
            },
            u32: 1 => {
                let (cmd, _, _) = vector_helper::unpack_payload_two(vpt_pld);
                let got_sod = cmd == u2:1;
                let got_eos = cmd == u2:3;
                let new_state = if (got_sod){u32: 20} else if (got_eos){u32: 30}else{state.0};
                (new_state, state.1, state.2, state.4, state.5, state.6)
            },
            u32: 20 => {
                let new_state = u32: 21;
                (new_state, state.1, state.2, vpt_pld, state.5, state.6)
            },
            u32: 21 => {
                let (cmd, _, _) = vector_helper::unpack_payload_two(state.4);
                let got_eod = cmd == u2:2;
                let new_state = if (got_eod) { u32: 30 } else { u32: 20 };
                (new_state, state.1, state.2, state.4, state.5, state.6)    
            },
            u32: 30 => {
                let new_state = u32: 31;
                (new_state, state.1, state.2, state.4, mpt_pld, state.6)
            },
            u32: 31 => {
                let cmd = state.5[94+:u2];
                let got_sod = cmd == u2:1;
                let got_eos = cmd == u2:3;
                let new_state = if (got_sod) {u32: 40} else if (got_eos) {u32: 5} else {u32: 30};
                (new_state, state.1, state.2, state.4, state.5, state.6)
            },
            u32: 40 => {
                let new_state = u32: 41;
                (new_state, state.1, state.2, state.4, mpt_pld, state.6)
            },
            u32: 41 => {
                let new_state = u32: 42;
                (new_state, state.1, state.2, state.4, state.5, state.6)
            },
            u32: 42 => {
                let new_state = u32: 43;
                (new_state, state.1, state.2, state.4, state.5, vd_pld)
            },
            u32: 43 => {                
                let cmd = state.5[94+:u2];
                let got_eod = cmd == u2:2;
                let new_state = if (got_eod) { u32: 5} else { u32: 40 };
                (new_state, state.1, state.2, state.4, state.5, state.6)
            },
            u32: 5 => {
                let new_cur_part = state.2 + u32: 1;
                let new_state = if (new_cur_part < (state.1 + u32: 1)) { u32: 1 } else { u32: 0 };
                (new_state, state.1, state.2, state.4, state.5, state.6)
            },
            _ => {(state.0, state.1, state.2, state.4, state.5, state.6)}
        };
        (st0, st1, st2, new_tok, st4, st5, st6)
    }
}