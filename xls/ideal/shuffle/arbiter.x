// pipeline depth is controlled via command flag --pipeline_stages
// this may have to be stiched together (generated alone with above flag,
// introduced into a greater project) to create the pipeline in such
// a manner, here filament style syntax i think would be useful.

// works on both payload twos and threes
pub fn arbiter<
    NUM_STREAMS: u32
>(
    payload:       uN[96][NUM_STREAMS],
    i_valid:                    u1[NUM_STREAMS],
    rotate_offset:              u32
) -> (
    uN[96][NUM_STREAMS],    // resend payload
    u1[NUM_STREAMS],        // resend payload valid
    u32[NUM_STREAMS],       // xbar select
    u1[NUM_STREAMS]         // xbar valid
) {
    // create the rotated addresses and valids
    let (reg_val_addrs, rot_val_addrs) = 
    for (ilid, (reg_addrs, rot_addrs)): (u32, (u32[NUM_STREAMS], u32[NUM_STREAMS])) in u32:0..NUM_STREAMS {
        let new_reg_addrs = update(reg_addrs, ilid, payload[ilid][64+:u30] as u32);
        let rot_lane_id = (ilid + rotate_offset) % NUM_STREAMS;
        let new_rot_addrs = update(rot_addrs, ilid, payload[rot_lane_id][64+:u30] as u32);
        (new_reg_addrs, new_rot_addrs)
    }((zero!<u32[NUM_STREAMS]>(), zero!<u32[NUM_STREAMS]>()));
    let i_v = i_valid as uN[NUM_STREAMS];
    let i_valid_rrotate = ((i_v << rotate_offset) | (i_v >> (NUM_STREAMS - rotate_offset))) as u1[NUM_STREAMS];
    
    // trace_fmt!("{:0x}", reg_val_addrs);
    // trace_fmt!("{:0x}", i_valid);
    // trace_fmt!("{:0x}", rot_val_addrs);
    // trace_fmt!("{:0x}", i_valid_rrotate);


    // updated crossbar selections based upon output of priority encoder for each output lane id
    let (xbar_valid, xbar_select) = 
    for (olid, (xbar_v, xbar_s)) : (u32, (u1[NUM_STREAMS], u32[NUM_STREAMS])) in u32:0..NUM_STREAMS {
        // priority encoder based upon the rotated addresses and valids
        // lowest index element wins
        let (input_port_found, rotated_input_port_id) = 
        for (rotated_ild, (rotated_ild_found, rotated_ild_port)) : (u32, (u1, u32)) in u32:0..NUM_STREAMS {
            let rev_indx: u32 = NUM_STREAMS - u32: 1 - rotated_ild;
            let (new_rotated_ild_found, new_rotated_ild_port) = 
            if (i_valid_rrotate[rev_indx] && (rot_val_addrs[rev_indx] % NUM_STREAMS) == olid){
                (u1: 1, rev_indx)
            }
            else {
                (rotated_ild_found, rotated_ild_port)
            };
            (new_rotated_ild_found, new_rotated_ild_port)
        }((u1:0, u32: 0));

        let (new_xbar_v, new_xbar_s) =
        if (input_port_found){
            // rotation back into regular addresses
            let unrotated_ilid = (rotated_input_port_id + rotate_offset) % NUM_STREAMS;
            (update(xbar_v, olid, u1: 1), update(xbar_s, olid, unrotated_ilid))
        }
        else {
            (xbar_v, xbar_s)
        };
        (new_xbar_v, new_xbar_s)
    }((zero!<u1[NUM_STREAMS]>(), zero!<u32[NUM_STREAMS]>()));

    // determine which packets must be resent given xbar_valid and xbar_select mappings
    let (resend_valid, resend_payload) =
    for (ilid, (resend_v, resend_p)) : (u32, (u1[NUM_STREAMS], uN[96][NUM_STREAMS])) in u32:0..NUM_STREAMS {
        let requested_olid = reg_val_addrs[ilid] % NUM_STREAMS;
        let request_granted = (
                                i_valid[ilid] && 
                                xbar_select[requested_olid] == ilid && 
                                xbar_valid[requested_olid]
                               );
        let (new_resend_v, new_resend_p) = 
        if (!request_granted && i_valid[ilid]) {
            (update(resend_v, ilid, u1:1), update(resend_p, ilid, payload[ilid]))
        }
        else {
            // NOTE!!!!! resend_p is ALWAYS a mirror of the input. it is ONLY
            // the VALID signal that differentiates the resend_p from either being
            // resent OR being passed through. Thus, despite it looking like an 
            // error that the reference hisparse shuffle core passes resend_payload
            // into the crossbar as input, it is in FACT a mirror of the original 
            // payload input
            (resend_v, update(resend_p, ilid, payload[ilid]))
        };
        (new_resend_v, new_resend_p)
    }((zero!<u1[NUM_STREAMS]>(), zero!<uN[96][NUM_STREAMS]>()));

    (
        payload,
        resend_valid,
        xbar_select,
        xbar_valid
    )
}

#[test]
fn arbiter_test() {
    // four stream example, conflict on the index for two indices
    let input: uN[96][4] = [u2: 0 ++ u30: 1 ++ u32: 1 ++ u32: 1,
                            u2: 0 ++ u30: 1 ++ u32: 2 ++ u32: 2, 
                            u2: 0 ++ u30: 2 ++ u32: 3 ++ u32: 3, 
                            u2: 0 ++ u30: 3 ++ u32: 4 ++ u32: 4];
    let input_valid: u1[4] = [u1: 1, u1: 1, u1: 1, u1: 0];
    let rotate_offset = u32: 1;
    let (
        resend_payload,
        resend_valid,
        xbar_select,
        xbar_valid
    ) = arbiter<u32: 4>(input, input_valid, rotate_offset);

    trace_fmt!("{:0x}", resend_payload);
    trace_fmt!("{:0x}", resend_valid);
    trace_fmt!("{:0x}", xbar_select);
    trace_fmt!("{:0x}", xbar_valid);
}

// I wanted a way to allow the arbiter to have some latency in computation.
// if the arbiter was to remain a func, anything that used the func (say the
// shuffler core proc) would have activations that were at least as long as the 
// latency of the arbiter. Making it a proc now, I can model the latent computation
// by non blocking receives on the host side: if the non blocking receive is false, 
// the arbiter is probably in the middle of the long latency computation
pub proc arbiter_wrapper<
    NUM_STREAMS: u32
>{
    payload:                    chan<uN[96][NUM_STREAMS]> in; // notice that this isnt a parametric channel, instead only accepting a single value
                                                              // shuffler core will create the single all-stream value from sampling each stream
    i_valid:                    chan<u1[NUM_STREAMS]> in;
    rotate_offset:              chan<u32>             in;

    // these should come N cycles later, where N is the pipeline depth
    // the arbiter func/this proc is synthesized with.
    resend_payload_type_two:    chan<uN[96][NUM_STREAMS]> out;
    resend_payload_valid:       chan<u1[NUM_STREAMS]>     out;
    xbar_select:                chan<u32[NUM_STREAMS]>    out;
    xbar_valid:                 chan<u1[NUM_STREAMS]>     out;
    original_input_valid:       chan<u1[NUM_STREAMS]>     out;

    config(
        payload:         chan<uN[96][NUM_STREAMS]> in,
        i_valid:                    chan<u1[NUM_STREAMS]> in,
        rotate_offset:              chan<u32> in,

        // these should come N cycles later, where N is the pipeline depth
        // the arbiter func/this proc is synthesized with.
        resend_payload_type_two:    chan<uN[96][NUM_STREAMS]> out,
        resend_payload_valid:       chan<u1[NUM_STREAMS]> out,
        xbar_select:                chan<u32[NUM_STREAMS]> out,
        xbar_valid:                 chan<u1[NUM_STREAMS]> out,
        original_input_valid:       chan<u1[NUM_STREAMS]> out 
    ) {
        (
            payload, i_valid, rotate_offset, 
            resend_payload_type_two, resend_payload_valid,
            xbar_select, xbar_valid, original_input_valid
        )
    }

    // simply order the activations such that
    // arbiter inputs have arbiter outputs in order
    init {(join())}

    next (order_token: token) {
        // we get the inputs as soon as possible
        let (itok1, ptt) = recv(join(), payload);
        let (itok2, iv) = recv(join(), i_valid);
        let (itok3, ro) = recv(join(), rotate_offset);
        // compute arbiter result in N cycles
        let (rptt, rpv, xs, xv) = arbiter<NUM_STREAMS>(ptt, iv, ro);
        // ensure results are ordered using the order token
        let order_token1 = send(order_token, resend_payload_type_two, rptt);
        let order_token2 = send(order_token, resend_payload_valid, rpv);
        let order_token3 = send(order_token, xbar_select, xs);
        let order_token4 = send(order_token, xbar_valid, xv);
        // to rectify what i think is an error, i will have the arbiter
        // send the old valid (so the arbiter basically pipelines the valid)
        let order_token5 = send(order_token, original_input_valid, iv);
        let new_order_token = join(order_token1, order_token2, order_token3, order_token4, order_token5);
        (new_order_token)
    }
}
