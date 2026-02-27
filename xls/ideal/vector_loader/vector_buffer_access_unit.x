import vector_helper;
// note the VAU operates on one stream
pub proc vecbuf_access_unit<
    BANK_SIZE:   u32,       // note BANK_SIZE = VB_SIZE / PACK_SIZE, aka
    NUM_STREAMS: u32        // we have PACK_SIZE number of banks that combine
                            // to make up the VB_SIZE
>{
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
        join()                       // 3 order token
    )}

    next(state: (u32, u32, u32, token)) {

        // trace_fmt!(" ");
        // trace_fmt!(" current state ");
        // trace_fmt!("---------------");
        // trace_fmt!("state  : {:0x}", state.0);
        // trace_fmt!("numcolp: {:0x}", state.1);
        // trace_fmt!("curcolp: {:0x}", state.2);
        // trace_fmt!("---------------");
        // trace_fmt!(" ");
        // trace_fmt!(" ");

        let new_state =
        // init state, read num_col_partitions in
        if (state.0 == u32: 0){
            let (new_tok, new_num_col_partitions) = recv(state.3, num_col_partitions);
            let new_cur_part = u32: 0;
            let new_state = u32: 1;
            (
                new_state, new_num_col_partitions, new_cur_part, new_tok
            )
        }
        else
        // new partition cleanup
        if (state.0 == u32: 1){
            let new_addr = u32: 0;
            let new_state = u32: 2;
            (
                new_state, state.1, state.2, state.3
            )
        }
        else
        // vector buffer bank loading state wait for SOD or EOS (from vector payloads)
        if (state.0 == u32: 2){
            let (new_tok, vector_payload) = recv(state.3, vector_payload_two);
            let (cmd, _, _) = vector_helper::unpack_payload_two(vector_payload);
            let got_sod = cmd == u2:1;
            let got_eos = cmd == u2:3;
            let new_state =
            if (got_sod){
                u32: 3
            }
            else
            if (got_eos){
                u32: 4 // if we got eos, we go straight to the vector "reader" portion so that it can get and send eos as well
            }
            else{
                state.0
            };
            (
                new_state, state.1, state.2, new_tok
            )
        }
        else
        // vector buffer bank loading state until EOD (from vector payloads)
        if (state.0 == u32: 3){
            let (new_tok, vector_payload) = recv(state.3, vector_payload_two);
            let (cmd, indx, data) = vector_helper::unpack_payload_two(vector_payload);
            let got_eod = cmd == u2:2;
            let new_state = if (got_eod) { u32: 4 } else { state.0 };
            let buf_addr = ((indx as u32) / NUM_STREAMS) % BANK_SIZE;
            // this module does both reads and writes to external memory.
            // to signify the type of operation, the top 2 bits of the addr (which are already 0 since
            // both row and col indx are at max u30s) will be the instruction type. 1 is a write, 2 is a read, 0 and 3 is reserved
            let new_tok = send_if(new_tok, vecbuf_bank_addr, !got_eod, u2: 1 ++ (buf_addr as u30));
            let new_tok = send_if(new_tok, vecbuf_dout, !got_eod, data);
            (
                new_state, state.1, state.2, new_tok
            )
        }
        else
        // vector buffer bank stream reads and creation of payload_type_three wait for SOD (from matrix payloads)
        if (state.0 == u32: 4){
            let (new_tok, matrix_payload) = recv(state.3, matrix_payload_two);
            let cmd = matrix_payload[94+:u2];
            let got_sod = cmd == u2:1;
            let got_eos = cmd == u2:3;
            let new_state = 
            if (got_sod) { 
                u32: 5
            } 
            else
            if (got_eos) {
                u32: 6
            }
            else {
                state.0
            };
            // either send SOD or EOS
            let new_tok = send_if(new_tok, payload_type_three, got_sod, u2: 1 ++ zero!<uN[94]>());
            let new_tok = send_if(new_tok, payload_type_three, got_eos, u2: 3 ++ zero!<uN[94]>());
            (
                new_state, state.1, state.2, new_tok
            )
        }
        else
        // vector buffer bank stream reads and creation of payload_type_three until EOD (from matrix payloads)
        if (state.0 == u32: 5){
            let (new_tok, matrix_payload) = recv(state.3, matrix_payload_two);
            let (cmd, col_indx, row_indx, data) = vector_helper::unpack_matrix_payload_two(matrix_payload);
            let cmd = matrix_payload[94+:u2];
            let got_eod = cmd == u2:2;
            let null_payload = matrix_payload == uN[96]:0;
            let request_bank_predicate = !(got_eod || null_payload);
            let new_state = if (got_eod) { u32: 6} else { state.0 };
            let bank_addr = ((col_indx as u32) / NUM_STREAMS) % BANK_SIZE;
            // read is u2: 2
            let new_tok = send_if(new_tok, vecbuf_bank_addr, request_bank_predicate, u2: 2 ++ (bank_addr as u30));
            let (new_tok, vec_val) = recv_if(new_tok, vecbuf_din, request_bank_predicate, u32: 0);
            let payload_three = 
            if (got_eod) 
            { u2: 2 ++ zero!<uN[94]>() } 
            else if (null_payload) // <----- fix to address failure to filter out null payloads
            { uN[96]: 0 }
            else 
            { vector_helper::matrix_vector_payload_merge(matrix_payload,vec_val ) };
            let new_tok = send(new_tok, payload_type_three, payload_three);
            (
                new_state, state.1, state.2, new_tok
            )
        }
        else
        // end of partition, increment current partition and determine next state
        if (state.0 == u32: 6){
            let new_cur_part = state.2 + u32: 1;
            let new_state = if (new_cur_part < (state.1 + u32: 1)) { u32: 1 } else { u32: 0 };
            (
                new_state, state.1, new_cur_part, state.3
            )
        }
        else {
            trace_fmt!("SHOULD NEVER ENTER THIS STATE!!!!!!!");
            state
        };
        (new_state)
        
    }
}