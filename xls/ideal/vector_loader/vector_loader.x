import vector_helper;

pub proc vector_loader<
    NUM_KERNELS: u32,
    NUM_STREAMS: u32,
    VB_SIZE:     u32,
    PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}
>{
    hbm_vector_payload:             chan<u32[NUM_STREAMS]> in;
    hbm_vector_addr:                chan<u32>             out;
    num_matrix_cols:                chan<u32>              in;
    
    vector_payload_one:             chan<uN[PAYLOAD_ONE_BITWIDTH]>[NUM_KERNELS] out;

    config(
        hbm_vector_payload:             chan<u32[NUM_STREAMS]> in,
        hbm_vector_addr:                chan<u32>             out,
        num_matrix_cols:                chan<u32>              in,
        vector_payload_one:             chan<uN[PAYLOAD_ONE_BITWIDTH]>[NUM_KERNELS] out
    ) {
        (hbm_vector_payload, hbm_vector_addr, num_matrix_cols, vector_payload_one)
    }

    init {(
        u32: 0,                 // 0 state
        // state 0 reset
        u32: 0,                 // 1 num col partitions
        u32: 0,                 // 2 num cols last partition
        u32: 0,                 // 3 cur col partition
        //
        // state 1 reset
        u32: 0,                 // 4 num packed payloads per partition
        u32: 0,                 // 5 cur partition index
        //
        join()                  // 6 order token
    )}

    next (state: (u32, u32, u32, u32, u32, u32, token)) {


        // trace_fmt!(" ");
        // trace_fmt!(" current state ");
        // trace_fmt!("---------------");
        // trace_fmt!("state  : {:0x}", state.0);
        // trace_fmt!("numcolp: {:0x}", state.1);
        // trace_fmt!("numcoll: {:0x}", state.2);
        // trace_fmt!("curcolp: {:0x}", state.3);
        // trace_fmt!("numpack: {:0x}", state.4);
        // trace_fmt!("curindx: {:0x}", state.5);
        // trace_fmt!("---------------");
        // trace_fmt!(" ");
        // trace_fmt!(" ");


        let new_state =
        // first boot
        if (state.0 == u32: 0){
            let (new_tok, num_cols) = recv(state.6, num_matrix_cols);
            let new_num_col_parts = (num_cols + VB_SIZE - 1) / VB_SIZE;
            let last_part = num_cols % VB_SIZE;
            let new_num_col_last_part = if (last_part == 0) { VB_SIZE } else { last_part };
            let new_state = u32: 1;
            let new_cur_col = u32: 0;
            (
                new_state, new_num_col_parts, new_num_col_last_part,
                new_cur_col, state.4, state.5, new_tok
            )
        }
        else
        // per partition reset
        if (state.0 == u32: 1){
            // send SOD
            let new_tok =
            for (idx, tok) : (u32, token) in u32:0..NUM_KERNELS{
                let n_tok = send(tok, vector_payload_one[idx], vector_helper::payload_converter<NUM_STREAMS>(zero!<u32[NUM_STREAMS]>(), u32: 0, u2: 1));
                (n_tok)
            }(state.6);
            // calc num packed payloads per partition
            let new_num_payloads = 
            if (state.3 == (state.1 - u32: 1)){
                (state.2 / NUM_STREAMS)
            }
            else {
                (VB_SIZE / NUM_STREAMS)
            };
            let new_cur_part_index = u32: 0;
            let new_state = u32: 2;
            (
                new_state, state.1, state.2, state.3,
                new_num_payloads, new_cur_part_index, new_tok
            )
            
        }
        else
        // partition stream
        if (state.0 == u32: 2){
            let requested_addr = state.5 + (state.3 * VB_SIZE) / NUM_STREAMS;
            let new_tok = send(state.6, hbm_vector_addr, requested_addr);
            let (new_tok, vector_payload) = recv(new_tok, hbm_vector_payload);
            let kernel_vector_payload = vector_helper::payload_converter<NUM_STREAMS>(vector_payload, requested_addr, u2: 0);
            let new_tok = 
            for (idx, tok) : (u32, token) in u32:0..NUM_KERNELS{
                let n_tok = send(tok, vector_payload_one[idx], kernel_vector_payload);
                (n_tok)
            }(new_tok);
            let new_cur_part_index = state.5 + u32: 1;
            let new_state = if (new_cur_part_index == state.4) { u32: 3 } else { state.0 };
            (
                new_state, state.1, state.2, state.3, 
                state.4, new_cur_part_index, new_tok
            )
        }
        else
        // send EOD, decide to send EOS or next partition
        if (state.0 == u32: 3){
            let new_tok =
            for (idx, tok) : (u32, token) in u32:0..NUM_KERNELS{
                let n_tok = send(tok, vector_payload_one[idx], vector_helper::payload_converter<NUM_STREAMS>(zero!<u32[NUM_STREAMS]>(), u32: 0, u2: 2));
                (n_tok)
            }(state.6);
            let new_cur_col_part = state.3 + u32: 1;
            let new_state = if ( new_cur_col_part == state.1 ) { u32: 4 } else { u32: 1 };
            (
                new_state, state.1, state.2, new_cur_col_part,
                state.4, state.5, new_tok
            )
        }
        else
        // send EOS, return to state 0
        if (state.0 == u32: 4){
            let new_tok =
            for (idx, tok) : (u32, token) in u32:0..NUM_KERNELS{
                let n_tok = send(tok, vector_payload_one[idx], vector_helper::payload_converter<NUM_STREAMS>(zero!<u32[NUM_STREAMS]>(), u32: 0, u2: 3));
                (n_tok)
            }(state.6);
            let new_state = u32: 0;
            (
                new_state, state.1, state.2,
                state.3, state.4, state.5, state.6
            )
        }
        else {
            trace_fmt!("SHOULD NEVER BE IN THIS STATE!!!");
            state
        };
        (new_state)
    }
}