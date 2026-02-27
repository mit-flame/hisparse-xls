// equivalent to result_drain in hisparse code, streams vector result updates in order
// to external HBM
pub proc kernels_results_merger<
    NUM_KERNELS: u32,
    OB_DIVIDED_BY_PACK_SIZE: u32,       // this is LOGICAL_OB_SIZE / PACK_SIZE, 
                                        // effectively num packed payloads per row partition
    NUM_STREAMS: u32,
    PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}
>{

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
        zero!<u32[NUM_KERNELS]>(),      // 2 saved num hbm channels per kernel (ACTUALLY MUST BE A PREFIX SUM OF THIS TO MAKE THE IF CONDITION LOOP WORK BELOW)
        u32: 0,                         // 3 sum of hbm channels per kernel
        zero!<u1[NUM_KERNELS]>(),       // 4 got EOS from the kernels
        u32: 0,                         // 5 kernel payload counter
        u32: 0,                         // 6 write out counter
        join()                          // 7 order token
    )}

    next(state: (u32, u32, u32[NUM_KERNELS], u32, u1[NUM_KERNELS], u32, u32, token)) {
        let new_state = 
        // read in the saved parts
        if (state.0 == u32: 0){
            let (new_token, new_current_row) = recv(state.7, current_row_partition);
            let (new_token, new_num_hbm_channels) = recv(new_token, num_hbm_channels_each_kernel);

            let new_sum_hbm_channels = for (idx, sum):(u32, u32) in u32:0..NUM_KERNELS { (sum + new_num_hbm_channels[idx]) }(u32: 0);
            let new_got_eos = zero!<u1[NUM_KERNELS]>();
            let new_kernel_pld_count = u32: 0;
            let new_write_out_count = u32: 0;
            let new_state = u32: 1;
            (
                new_state, new_current_row, new_num_hbm_channels, new_sum_hbm_channels, new_got_eos, new_kernel_pld_count, new_write_out_count, new_token
            )
        }
        else
        // for invalid kernel reads (already sent EOS for example) it will just iterate through without doing the recv until it hits a valid recv
        // once and_reduce got eos is true, go back to state 0
        if (state.0 == u32: 1){
            // first figure out which kernel to read
            let kernel_read_indx_mod = state.5 % state.3;
            let new_kernel_read_indx = state.5 + u32: 1;
            let (kernel_read_indx, kernel_read_valid) = 
            for (idx, (read_indx, valid)) : (u32, (u32, u1)) in u32:0..NUM_KERNELS{
                let rev_indx = NUM_KERNELS - u32: 1 - idx; // reversed to prioritize earlier indices just like the source code
                let n_read_indx = if (kernel_read_indx_mod < state.2[rev_indx]){ rev_indx } else { read_indx };
                let n_valid = if (kernel_read_indx_mod < state.2[rev_indx]){ u1: 1 } else { valid };
                (n_read_indx, n_valid)
            }((u32: 0, u1: 0));
            let kernel_read_valid = kernel_read_valid && !(state.4[kernel_read_indx]);
            // trace_fmt!("current kernel read index {:0x} reading {:0x} valid {:0x} mod {:0x} state 2 {:0x}", state.5, kernel_read_indx, kernel_read_valid, kernel_read_indx_mod, state.2);
            let (new_token, kernel_payload_one) = recv_if(state.7, multikernel_vector_payload_one[kernel_read_indx], kernel_read_valid, zero!<uN[PAYLOAD_ONE_BITWIDTH]>());

            // then determine if got eos
            let got_eos = kernel_payload_one[(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 3;
            let got_eod = kernel_payload_one[(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 2;
            let got_sod = kernel_payload_one[(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] == u2: 1;
            let new_got_eos = if (got_eos) { update(state.4, kernel_read_indx, got_eos) } else { state.4 };

            // finally determine if we should send the kernel_payload
            let payload_addr_offset = state.1 * OB_DIVIDED_BY_PACK_SIZE;
            let payload_addr = state.6 + payload_addr_offset;
            let hbm_send_valid = kernel_read_valid && !got_eos && !got_sod && !got_eod;
            let new_write_out_count = if (hbm_send_valid) { state.6 + u32: 1 } else { state.6 };
            let new_token = send_if(new_token, hbm_vector_addr, hbm_send_valid, payload_addr);
            let new_token = send_if(new_token, hbm_vector_payload, hbm_send_valid, (kernel_payload_one[0:(NUM_STREAMS << u32: 5) as s32]) as u32[NUM_STREAMS]);

            // state calculation
            let new_state =  if (and_reduce(new_got_eos as uN[NUM_KERNELS])){ u32: 0 } else { state.0 };
            (
                new_state, state.1, state.2, state.3, new_got_eos, new_kernel_read_indx, new_write_out_count, new_token
            )
        }
        else{
            trace_fmt!("SHOULD NEVER BE HERE!!!");
            state
        };
        new_state
    }
}