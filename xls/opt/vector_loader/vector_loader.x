import vector_helper;

pub proc vector_loader<NUM_KERNELS: u32,NUM_STREAMS: u32,VB_SIZE: u32,PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}>
{
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
        u32: 0,                 // 1 num col partitions
        u32: 0,                 // 2 num cols last partition
        u32: 0,                 // 3 cur col partition
        u32: 0,                 // 4 num packed payloads per partition
        u32: 0,                 // 5 cur partition index
        join(),                 // 6 order token
        // non original proc state
        zero!<u32[NUM_STREAMS]>()   // 7 latched hbm_vector_payload
    )}

    next (state: (u32, u32, u32, u32, u32, u32, token, u32[NUM_STREAMS])) {

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

        let (
            hva_tx, vpo_tx,
            hvp_rx, nmc_rx
        ) = 
        match (state.0) {
            u32: 0 => {(false, false, false, true)},
            u32: 1 => {(false, true, false, false)},
            u32: 20 => {(true, false, false, false)},
            u32: 21 => {(false, false, true, false)},
            u32: 22 => {(false, true, false, false)},
            u32: 30 => {(false, true, false, false)},
            u32: 4 => {(false, true, false, false)},
            _=>{(false, false, false, false)}
        };

        let (
            hva_pld, vpo_pld
        ) =
        match (state.0) {
            u32: 1 => {
                let vpo_pld = 
                for (idx, pld) : (u32, uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS]) in u32:0..NUM_KERNELS {
                    let n_pld = update(pld, idx, vector_helper::payload_converter<NUM_STREAMS>(zero!<u32[NUM_STREAMS]>(), u32: 0, u2: 1));
                    (n_pld)
                }(zero!<uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS]>());
                (u32: 0, vpo_pld)
            },
            u32: 20 => {
                let requested_addr = state.5 + (state.3 * VB_SIZE) / NUM_STREAMS;
                (requested_addr, zero!<uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS]>())
            },
            u32: 22 => {
                let requested_addr = state.5 + (state.3 * VB_SIZE) / NUM_STREAMS;
                let vpo_pld = 
                for (idx, pld) : (u32, uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS]) in u32:0..NUM_KERNELS{
                    let n_pld = update(pld, idx, vector_helper::payload_converter<NUM_STREAMS>(state.7, requested_addr, u2: 0));
                    (n_pld)
                }(zero!<uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS]>());
                (u32: 0, vpo_pld)
            },
            u32: 30 => {
                let vpo_pld = 
                for (idx, pld) : (u32, uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS]) in u32:0..NUM_KERNELS {
                    let n_pld = update(pld, idx, vector_helper::payload_converter<NUM_STREAMS>(zero!<u32[NUM_STREAMS]>(), u32: 0, u2: 2));
                    (n_pld)
                }(zero!<uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS]>());
                (u32: 0, vpo_pld)
            },
            u32: 4 => {
                let vpo_pld = 
                for (idx, pld) : (u32, uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS]) in u32:0..NUM_KERNELS {
                    let n_pld = update(pld, idx, vector_helper::payload_converter<NUM_STREAMS>(zero!<u32[NUM_STREAMS]>(), u32: 0, u2: 3));
                    (n_pld)
                }(zero!<uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS]>());
                (u32: 0, vpo_pld)
            },
            _=>{(u32: 0, zero!<uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS]>())}
        };
        let t1 = send_if(state.6, hbm_vector_addr, hva_tx, hva_pld);
        let t2 = 
        unroll_for! (idx, tok) : (u32, token) in u32:0..NUM_KERNELS{
            let n_tok = send_if(tok, vector_payload_one[idx], vpo_tx, vpo_pld[idx]);
            (n_tok)
        }(state.6);
        let (t3, hvp_pld) = recv_if(state.6, hbm_vector_payload, hvp_rx, zero!<u32[NUM_STREAMS]>());
        let (t4, nmc_pld) = recv_if(state.6, num_matrix_cols, nmc_rx, u32: 0);
        let new_tok = join(t1, t2, t3, t4);

        let (
            st0, st1, st2, st3, st4, st5, st7
        ) =
        match (state.0) {
            u32: 0 => {
                let new_num_col_parts = (nmc_pld + VB_SIZE - 1) / VB_SIZE;
                let last_part = nmc_pld % VB_SIZE;
                let new_num_col_last_part = if (last_part == 0) { VB_SIZE } else { last_part };
                let new_state = u32: 1;
                let new_cur_col = u32: 0;
                (
                    new_state, new_num_col_parts, new_num_col_last_part,
                    new_cur_col, state.4, state.5, state.7
                )
            },
            u32: 1 => {
                let new_state = u32: 20;
                let new_num_payloads = 
                if (state.3 == (state.1 - u32: 1)){
                    (state.2 / NUM_STREAMS)
                }
                else {
                    (VB_SIZE / NUM_STREAMS)
                };
                let new_cur_part_index = u32: 0;
                (
                    new_state, state.1, state.2, state.3,
                    new_num_payloads, new_cur_part_index, state.7
                )
            },
            u32: 20 => {
                let new_state = u32: 21;
                (
                    new_state, state.1, state.2, state.3, state.4, state.5, state.7
                )
            },
            u32: 21 => {
                let new_state = u32: 22;
                (
                    new_state, state.1, state.2, state.3, state.4, state.5, hvp_pld
                )
            },
            u32: 22 => {
                let new_cur_part_index = state.5 + u32: 1;
                let new_state = if (new_cur_part_index == state.4) { u32: 30 } else { u32: 20 };
                (
                    new_state, state.1, state.2, state.3, state.4, new_cur_part_index, state.7
                )
            },
            u32: 30 => {
                let new_cur_col_part = state.3 + u32: 1;
                let new_state = if ( new_cur_col_part == state.1 ) { u32: 4 } else { u32: 1 };
                (
                    new_state, state.1, state.2, new_cur_col_part, state.4, state.5, state.7
                )
            },
            u32: 4 => {
                let new_state = u32: 0;
                (new_state, state.1, state.2, state.3, state.4, state.5, state.7)
            },
            _=>{(state.0, state.1, state.2, state.3, state.4, state.5, state.7)}
        };

        (st0, st1, st2, st3, st4, st5, new_tok, st7)
    }
}