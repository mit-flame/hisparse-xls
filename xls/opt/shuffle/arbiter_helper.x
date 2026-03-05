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

pub struct ArbOut<NUM_STREAMS: u32>{
    rptt: uN[96][NUM_STREAMS],
    rpv: u1[NUM_STREAMS],
    xs: u32[NUM_STREAMS],
    xv: u1[NUM_STREAMS],
    oiv: u1[NUM_STREAMS]
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