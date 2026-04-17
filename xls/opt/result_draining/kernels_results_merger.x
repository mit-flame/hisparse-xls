pub proc kernels_results_merger<NUM_KERNELS: u32, OB_DIVIDED_BY_PACK_SIZE: u32, NUM_STREAMS: u32, PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}>
{
    current_row_partition:                      chan<u32>   in;
    num_hbm_channels_each_kernel:               chan<u32[NUM_KERNELS]>  in; // in the hisparse source code, its 4 for kernel 0, 6 for kernel 1 and 6 for kernel 2
    multikernel_vector_payload_one:             chan<uN[PAYLOAD_ONE_BITWIDTH]>[NUM_KERNELS] in;

    hbm_vector_addr:                            chan<u32>   out;
    hbm_vector_payload:                         chan<u32[NUM_STREAMS]>  out;

    config(
        current_row_partition:                      chan<u32>   in,
        num_hbm_channels_each_kernel:               chan<u32[NUM_KERNELS]>  in,
        multikernel_vector_payload_one:             chan<uN[PAYLOAD_ONE_BITWIDTH]>[NUM_KERNELS] in,

        hbm_vector_addr:                            chan<u32>   out,
        hbm_vector_payload:                         chan<u32[NUM_STREAMS]>  out
    ) {
        (
            current_row_partition, num_hbm_channels_each_kernel, multikernel_vector_payload_one, hbm_vector_addr, hbm_vector_payload
        )
    }

    init{(
        u32: 0,                         // 0 state
        u32: 0,                         // 1 saved current row partition number
        zero!<u3[NUM_KERNELS]>(),      // 2 saved num hbm channels per kernel (ACTUALLY MUST BE A PREFIX SUM OF THIS TO MAKE THE IF CONDITION LOOP WORK BELOW)
        u3: 0,                         // 3 sum of hbm channels per kernel
        zero!<u1[NUM_KERNELS]>(),       // 4 got EOS from the kernels
        u3: 0,                         // 5 kernel payload counter
        u32: 0,                         // 6 write out counter
        join(),                         // 7 order token
        // substate
        zero!<uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS]>()  // 8 latched kernel payload one

    )}

    next(state: (u32, u32, u3[NUM_KERNELS], u3, u1[NUM_KERNELS], u3, u32, token, uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS])) {
        let (hva_tx, hvp_tx, crp_rx, nhcek_rx, mvpo_rx) =
        match (state.0) {
            u32: 0 => {(false, false, true, true, zero!<u1[NUM_KERNELS]>())},
            u32: 1 => {
                let kernel_read_indx_mod = state.5 % state.3;
                let (kernel_read_indx, kernel_read_valid) = 
                for (idx, (read_indx, valid)) : (u32, (u32, u1)) in u32:0..NUM_KERNELS{
                    let rev_indx = NUM_KERNELS - u32: 1 - idx; // reversed to prioritize earlier indices just like the source code
                    let n_read_indx = if (kernel_read_indx_mod < state.2[rev_indx]){ rev_indx } else { read_indx };
                    let n_valid = if (kernel_read_indx_mod < state.2[rev_indx]){ u1: 1 } else { valid };
                    (n_read_indx, n_valid)
                }((u32: 0, u1: 0));
                let kernel_read_valid = kernel_read_valid && !(state.4[kernel_read_indx]);
                (false, false, false, false, update(zero!<u1[NUM_KERNELS]>(), kernel_read_indx, kernel_read_valid))
            },
            u32: 2 => {
                let kernel_read_indx_mod = state.5 % state.3;
                let (kernel_read_indx, kernel_read_valid) = 
                for (idx, (read_indx, valid)) : (u32, (u32, u1)) in u32:0..NUM_KERNELS{
                    let rev_indx = NUM_KERNELS - u32: 1 - idx; // reversed to prioritize earlier indices just like the source code
                    let n_read_indx = if (kernel_read_indx_mod < state.2[rev_indx]){ rev_indx } else { read_indx };
                    let n_valid = if (kernel_read_indx_mod < state.2[rev_indx]){ u1: 1 } else { valid };
                    (n_read_indx, n_valid)
                }((u32: 0, u1: 0));
                let kernel_read_valid = kernel_read_valid && !(state.4[kernel_read_indx]);
                let got_eos = state.8[kernel_read_indx][(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 3;
                let got_eod = state.8[kernel_read_indx][(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 2;
                let got_sod = state.8[kernel_read_indx][(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 1;
                let hbm_send_valid = kernel_read_valid && !got_eos && !got_sod && !got_eod;
                (hbm_send_valid, hbm_send_valid, false, false, zero!<u1[NUM_KERNELS]>())
            },
            _ => {(false, false, false, false, zero!<u1[NUM_KERNELS]>())}
        };

        let (hva_pld, hvp_pld) =
        match (state.0) {
            u32: 2 => {
                let payload_addr_offset = state.1 * OB_DIVIDED_BY_PACK_SIZE;
                let payload_addr = state.6 + payload_addr_offset;
                let kernel_read_indx_mod = state.5 % state.3;
                let kernel_read_indx = 
                for (idx, read_indx) : (u32, u32) in u32:0..NUM_KERNELS{
                    let rev_indx = NUM_KERNELS - u32: 1 - idx; // reversed to prioritize earlier indices just like the source code
                    let n_read_indx = if (kernel_read_indx_mod < state.2[rev_indx]){ rev_indx } else { read_indx };
                    (n_read_indx)
                }(u32: 0);
                (payload_addr, (state.8[kernel_read_indx][0:(NUM_STREAMS << u32: 5) as s32]) as u32[NUM_STREAMS])
            },
            _ => {(u32: 0, zero!<u32[NUM_STREAMS]>())}
        };

        let t0 = send_if(state.7, hbm_vector_addr, hva_tx, hva_pld);
        let t1 = send_if(state.7, hbm_vector_payload, hvp_tx, hvp_pld);
        let (t2, crp_pld) = recv_if(state.7, current_row_partition, crp_rx, u32: 0);
        let (t3, nhcek_pld) = recv_if(state.7, num_hbm_channels_each_kernel, nhcek_rx, zero!<u32[NUM_KERNELS]>());
        let (t4, mvpo_pld) = 
        unroll_for! (idx, (tok, pld)) : (u32, (token, uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS])) in u32:0..NUM_KERNELS {
            let (tok, spld) = recv_if(tok, multikernel_vector_payload_one[idx], mvpo_rx[idx] == u1: 1, uN[PAYLOAD_ONE_BITWIDTH]: 0);
            let n_pld = update(pld, idx, spld);
            (tok, n_pld)
        }((state.7, zero!<uN[PAYLOAD_ONE_BITWIDTH][NUM_KERNELS]>()));
        let new_tok = join(t0, t1, t2, t3, t4);

        let (st0, st1, st2, st3, st4, st5, st6, st8) =
        match (state.0) {
            u32: 0 => {
                let new_sum_hbm_channels = for (idx, sum):(u32, u32) in u32:0..NUM_KERNELS { (sum + nhcek_pld[idx]) }(u32: 0);
                let new_got_eos = zero!<u1[NUM_KERNELS]>();
                let new_kernel_pld_count = u32: 0;
                let new_write_out_count = u32: 0;
                let new_state = u32: 1;
                let new_nhcek_pld =
                for (idx, pld) : (u32, u3[NUM_KERNELS]) in u32:0..NUM_KERNELS {
                    let n_pld = update(pld, idx, nhcek_pld[idx] as u3);
                    (n_pld)
                }(zero!<u3[NUM_KERNELS]>());
                (
                    new_state, crp_pld, new_nhcek_pld, new_sum_hbm_channels as u3, 
                    new_got_eos, new_kernel_pld_count as u3, new_write_out_count, state.8
                )
            },
            u32: 1 => {
                let new_state = u32: 2;
                (new_state, state.1, state.2, state.3, state.4, state.5, state.6, mvpo_pld)
            },
            u32: 2 => {
                let kernel_read_indx_mod = state.5 % state.3;
                let new_kernel_read_indx = state.5 + u3: 1;
                let (kernel_read_indx, kernel_read_valid) = 
                for (idx, (read_indx, valid)) : (u32, (u32, u1)) in u32:0..NUM_KERNELS{
                    let rev_indx = NUM_KERNELS - u32: 1 - idx; // reversed to prioritize earlier indices just like the source code
                    let n_read_indx = if (kernel_read_indx_mod < state.2[rev_indx]){ rev_indx } else { read_indx };
                    let n_valid = if (kernel_read_indx_mod < state.2[rev_indx]){ u1: 1 } else { valid };
                    (n_read_indx, n_valid)
                }((u32: 0, u1: 0));
                let got_eos = state.8[kernel_read_indx][(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 3;
                let got_eod = state.8[kernel_read_indx][(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 2;
                let got_sod = state.8[kernel_read_indx][(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 1;
                let new_got_eos = if (got_eos) { update(state.4, kernel_read_indx, got_eos) } else { state.4 };
                let kernel_read_valid = kernel_read_valid && !(state.4[kernel_read_indx]);
                let hbm_send_valid = kernel_read_valid && !got_eos && !got_sod && !got_eod;
                let new_write_out_count = if (hbm_send_valid) { state.6 + u32: 1 } else { state.6 };
                let new_state =  if (and_reduce(new_got_eos as uN[NUM_KERNELS])){ u32: 0 } else { u32: 1 };
                (
                    new_state, state.1, state.2, state.3, new_got_eos, new_kernel_read_indx, new_write_out_count, state.8
                )
            },
            _ => {(state.0, state.1, state.2, state.3, state.4, state.5, state.6, state.8)}
        };

        (st0, st1, st2, st3, st4, st5, st6, new_tok, st8)
    }
}