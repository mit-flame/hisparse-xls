// upon seeing CMD on any stream, pauses all streams until CMD is seen, send command all at once, then continues
// padding with zeros if not seeing command
pub proc generic_syncer<NUM_STREAMS: u32, COMMAND: u2>
{
    multistream_payload_i:                 chan<uN[96]>[NUM_STREAMS] in;
    multistream_payload_o:                 chan<uN[96]>[NUM_STREAMS] out;

    config(
        multistream_payload_i:                 chan<uN[96]>[NUM_STREAMS] in,
        multistream_payload_o:                 chan<uN[96]>[NUM_STREAMS] out
    ){
        (
            multistream_payload_i, multistream_payload_o
        )
    }

    init{(
        zero!<u1[NUM_STREAMS]>(),       // seen CMD
        token()                         // order token
    )}

    next (state: (u1[NUM_STREAMS], token)) {
        let pause_lanes = or_reduce(state.0 as uN[NUM_STREAMS]);
        let (tok, pld, new_seen) = 
        unroll_for! (idx, (tok, payload, seen)) : (u32, (token, uN[96][NUM_STREAMS], u1[NUM_STREAMS])) in u32:0..NUM_STREAMS {
            let recv = if (pause_lanes) { if (state.0[idx] == u1: 0) { true } else { false } } else { true };
            let (n_tok, spld) = recv_if(tok, multistream_payload_i[idx], recv, uN[96]: 0);
            let n_seen = if (spld[94+:u2] == COMMAND) { update(seen, idx, u1: 1) } else { seen };
            let spld = if (spld[94+:u2] == COMMAND) { uN[96]: 0 } else { spld };
            let n_payload = update(payload, idx, spld);
            (n_tok, n_payload, n_seen)
        }((state.1, zero!<uN[96][NUM_STREAMS]>(), state.0));
        
        let send_cmd = if (and_reduce(new_seen as uN[NUM_STREAMS])) { true } else { false };
        let tok =
        unroll_for! (idx, tok) : (u32, token) in u32:0..NUM_STREAMS {
            let opld = if (send_cmd) { COMMAND ++ uN[94]: 0 } else { pld[idx] };
            let n_tok = send(tok, multistream_payload_o[idx], opld);
            (n_tok)
        }(tok);
        let new_seen = if (and_reduce(new_seen as uN[NUM_STREAMS])) { zero!<u1[NUM_STREAMS]>() } else { new_seen };
        (new_seen, tok)
    }
}