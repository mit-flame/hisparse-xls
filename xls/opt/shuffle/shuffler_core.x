import crossbar;
import matrix_helper;
import arbiter_helper;

pub proc shuffler_core <NUM_STREAMS: u32, FLUSH_ITERS: u32> // this will be dependent on the synthesized arbiter pipeline depth
{
    multistream_payload_i:                 chan<uN[96]>[NUM_STREAMS] in;
    multistream_payload_o:                 chan<uN[96]>[NUM_STREAMS] out;

    // arbiter proc members
    arbiter_payload_type_two_i:         chan<uN[96][NUM_STREAMS]> out;
    arbiter_i_valid:                    chan<u1[NUM_STREAMS]>     out;
    arbiter_rotate_offset:              chan<u32>                 out;
    arbiter_combined_in:                chan<arbiter_helper::ArbOut<NUM_STREAMS>> in;

    config(
        multistream_payload_i:       chan<uN[96]>[NUM_STREAMS] in,
        multistream_payload_o:       chan<uN[96]>[NUM_STREAMS] out,

        // externally synthesized arbiter
        arbiter_payload_type_two_i:         chan<uN[96][NUM_STREAMS]> out,
        arbiter_i_valid:                    chan<u1[NUM_STREAMS]>     out,
        arbiter_rotate_offset:              chan<u32>                 out,
        arbiter_combined_in:                chan<arbiter_helper::ArbOut<NUM_STREAMS>> in
    ) {
        (
            multistream_payload_i, multistream_payload_o,

            arbiter_payload_type_two_i, arbiter_i_valid, arbiter_rotate_offset, arbiter_combined_in
        )
    }

    init {(
        u32: 0,                             // 0 the actual state
        zero!<u1[NUM_STREAMS]>(),           // 1 fetch complete
        FLUSH_ITERS,                        // 2 flush counter
        u32: 0,                             // 3 rotate prioritiy
        join(),                             // 4 order token


        // substate (not found in original proc)
        zero!<uN[96][NUM_STREAMS]>(),       // 5 arbiter resend payload type two
        zero!<u1[NUM_STREAMS]>(),           // 6 arbiter resend payload valid
        zero!<u32[NUM_STREAMS]>(),          // 7 arbiter crossbar select
        zero!<u1[NUM_STREAMS]>(),           // 8 arbiter crossbar valid
        zero!<u1[NUM_STREAMS]>(),           // 9 arbiter original input valid
        zero!<uN[96][NUM_STREAMS]>()        // 10 multistream payload type two in
    )}

    // !!! anything that isnt either updated or reset by a given state must be passed through by said state !!!
    next (state: (u32, u1[NUM_STREAMS], u32, u32, token, uN[96][NUM_STREAMS], u1[NUM_STREAMS], u32[NUM_STREAMS], u1[NUM_STREAMS], u1[NUM_STREAMS], uN[96][NUM_STREAMS])) {

        // 1) Calculation of TX/RX boolean variables
        let (mp_tx, aptt_tx, av_tx, aro_tx,     mp_rx, aci_rx) =
        match (state.0){
            u32: 0 => {
                (false, false, false, false,    zero!<u1[NUM_STREAMS]>(), true)
            },
            u32: 1 => {
                let new_pred = 
                for (idx, pred) : (u32, u1[NUM_STREAMS]) in u32:0..NUM_STREAMS{
                    let spred = !state.6[idx] && !state.1[idx];
                    let n_pred = update(pred, idx, spred);
                    (n_pred)
                }(zero!<u1[NUM_STREAMS]>());
                (false, false, false, false,    new_pred, false)
            },
            u32: 2 => {
                (false, true, true, true,       zero!<u1[NUM_STREAMS]>(), false)
            },
            u32: 3 => {
                (true, false, false, false,     zero!<u1[NUM_STREAMS]>(), false)
            },
            u32: 10 => {
                (false, false, false, false,    zero!<u1[NUM_STREAMS]>(), true)
            },
            u32: 11 => {
                (true, true, true, true,        zero!<u1[NUM_STREAMS]>(), false)
            },
            u32: 20 => {
                (true, false, false, false,     zero!<u1[NUM_STREAMS]>(), false)
            },
            _ => {
                (false, false, false, false,    zero!<u1[NUM_STREAMS]>(), false)
            }
        };

        // 2) Calculation of send payloads
        let (mpo_pld, aptt_pld, av_pld, aro_pld) =
        match (state.0) {
            u32: 2 => {
                let (new_valid, new_payload) =
                for (idx, (valid, payload)) : (u32, (u1[NUM_STREAMS], uN[96][NUM_STREAMS])) in u32:0..NUM_STREAMS {
                    let resend_predicate = state.6[idx];
                    // all resend packets OR all packets that are not EOD inst NOR fetch already is complete
                    let valid_predicate = resend_predicate || (state.10[idx][94+:u2] != u2:2 && !state.1[idx] && state.10[idx][0+:u32] != u32: 0);
                    let p = if (resend_predicate) { state.5[idx] } else { state.10[idx] };
                    let new_v = update(valid, idx, valid_predicate);
                    let new_p = update(payload, idx, p);
                    (new_v, new_p)
                }((zero!<u1[NUM_STREAMS]>(), zero!<uN[96][NUM_STREAMS]>()));
                (zero!<uN[96][NUM_STREAMS]>(), new_payload, new_valid, state.3)
            },
            u32: 3 => {
                let mpo_pld = crossbar::crossbar<NUM_STREAMS>(state.5, state.9, state.8, state.7);
                (mpo_pld, zero!<uN[96][NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>(), u32: 0)
            },
            u32: 11 => {
                // do NOT send 0s to arbiter if there is a resend payload
                let mpo_pld = crossbar::crossbar<NUM_STREAMS>(state.5, state.9, state.8, state.7);
                (mpo_pld, state.5, state.6, state.3)
            },
            u32: 20 => {
                let mpo_pld = 
                for (idx, pld) : (u32, uN[96][NUM_STREAMS]) in u32:0..NUM_STREAMS{
                    let sp = matrix_helper::payload_converter<NUM_STREAMS>(zero!<uN[64]>(), u32: 0, u2: 2);
                    let n_pld = update(pld, idx, sp);
                    (n_pld)
                }(zero!<uN[96][NUM_STREAMS]>());
                (mpo_pld, zero!<uN[96][NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>(), u32: 0)
            },
            _ => {
                (zero!<uN[96][NUM_STREAMS]>(), zero!<uN[96][NUM_STREAMS]>(), zero!<u1[NUM_STREAMS]>(), u32: 0)
            }
        };

        // state print for debugging
        // trace_fmt!(" ");
        // trace_fmt!(" current state ");
        // trace_fmt!("---------------");
        // trace_fmt!("state  : {:0x}", state.0);
        // trace_fmt!("resend_pld  : {:0x}", state.5);
        // trace_fmt!("resend_pld_valid  : {:0x}", state.6);
        // trace_fmt!("xbar_sel  : {:0x}", state.7);
        // trace_fmt!("xbar_val  : {:0x}", state.8);
        // trace_fmt!("orig_inp_v  : {:0x}", state.9);
        // trace_fmt!("msp_2_in  : {:0x}", state.10);
        // trace_fmt!("---------------");
        // trace_fmt!(" ");
        // trace_fmt!(" ");
        // debug print of bool variables
        // trace_fmt!("mp_tx {:0x} aptt_tx {:0x} av_tx {:0x} aro_tx {:0x}     mp_rx {:0x} aci_rx {:0x}", mp_tx, aptt_tx, av_tx, aro_tx,     mp_rx, aci_rx);
        // outgoing payloads
        // trace_fmt!("mpo_pld {:0x} aptt_pld {:0x} av_pld {:0x} aro_pld {:0x}", mpo_pld, aptt_pld, av_pld, aro_pld);

        // 3) Sends and Receives.
        let t1 = 
        unroll_for! (idx, tok) : (u32, token) in u32:0..NUM_STREAMS{
            let n_tok = send_if(tok, multistream_payload_o[idx], mp_tx, mpo_pld[idx]);
            (n_tok)
        }(state.4);
        let t2 = send_if(state.4, arbiter_payload_type_two_i, aptt_tx, aptt_pld);
        let t3 = send_if(state.4, arbiter_i_valid, av_tx, av_pld);
        let t4 = send_if(state.4, arbiter_rotate_offset, aro_tx, aro_pld);

        let (t5, arbout_pld, _) = recv_if_non_blocking(state.4, arbiter_combined_in, aci_rx, zero!<arbiter_helper::ArbOut<NUM_STREAMS>>());
        let arpv_pld = arbout_pld.rpv;
        let arptt_pld = arbout_pld.rptt;
        let axs_pld = arbout_pld.xs;
        let axv_pld = arbout_pld.xv;
        let aoiv_pld = arbout_pld.oiv;
        let (t6, mp_pld) =
        unroll_for! (idx, (tok, mp)) : (u32, (token, uN[96][NUM_STREAMS])) in u32:0..NUM_STREAMS {
            let (n_tok, sp) = recv_if(tok, multistream_payload_i[idx], mp_rx[idx] == u1: 1, zero!<uN[96]>()); // note mp_rx must be an array
            let n_mp = update(mp, idx, sp);
            (n_tok, n_mp)
        }((state.4, zero!<uN[96][NUM_STREAMS]>()));
        let new_tok = join(t1, t2, t3, t4, t5, t6);

        // 4) State updates
        let (st0, st1, st2, st3, st5, st6, st7, st8, st9, st10) =
        match (state.0) {
            u32: 0 => {
                let new_state = u32: 1;
                (
                    new_state, state.1, state.2, state.3,
                    arptt_pld, arpv_pld, axs_pld, axv_pld, aoiv_pld, state.10
                )
            },
            u32: 1 => {
                let new_state = u32: 2;
                (
                    new_state, state.1, state.2, state.3,
                    state.5, state.6, state.7, state.8, state.9, mp_pld
                )
            },
            u32: 2 => {
                let new_fetch_complete =
                for (idx, fetch_complete) : (u32, u1[NUM_STREAMS]) in u32:0..NUM_STREAMS {
                    // either the fetch was already complete or it just completed
                    let fetch_complete_predicate = state.1[idx] || state.10[idx][94+:u2] == u2:2;
                    let new_f_c = update(fetch_complete, idx, fetch_complete_predicate);
                    (new_f_c)
                }(zero!<u1[NUM_STREAMS]>());
                let next_rotate_priority = (state.3 + u32: 1) % NUM_STREAMS;
                let new_state = u32: 3;
                (
                    new_state, new_fetch_complete, state.2, next_rotate_priority,
                    state.5, state.6, state.7, state.8, state.9, state.10
                )
            },
            u32: 3 => {
                let new_state = if (and_reduce(state.1 as uN[NUM_STREAMS])) { u32: 10 } else { u32: 0 };
                (
                    new_state, state.1, state.2, state.3,
                    state.5, state.6, state.7, state.8, state.9, state.10 
                )
            },
            u32: 10 => {
                let new_state = u32: 11;
                (
                    new_state, state.1, state.2, state.3,
                    arptt_pld, arpv_pld, axs_pld, axv_pld, aoiv_pld, state.10
                )
            },
            u32: 11 => {
                let next_rotate_priority = (state.3 + u32: 1) % NUM_STREAMS;
                let new_flush_counter = state.2 - u32: 1;
                let new_state = if (new_flush_counter == u32: 0) { u32: 20 } else { u32: 10 };
                (
                    new_state, state.1, new_flush_counter, next_rotate_priority,
                    state.5, state.6, state.7, state.8, state.9, state.10
                )
            },
            u32: 20 => {
                let new_state = u32: 0;
                (
                    new_state, zero!<u1[NUM_STREAMS]>(), FLUSH_ITERS, u32: 0,
                    state.5, state.6, state.7, state.8, state.9, state.10
                )
            },
            _ => {
                (
                    state.0, state.1, state.2, state.3,
                    state.5, state.6, state.7, state.8, state.9, state.10
                )
            }
        };
        (st0, st1, st2, st3, new_tok, st5, st6, st7, st8, st9, st10)
    }

}