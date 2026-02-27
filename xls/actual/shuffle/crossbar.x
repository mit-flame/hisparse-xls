// works for both payload type twos and threes
pub fn crossbar<
    NUM_STREAMS: u32
>(
    payload:     uN[96][NUM_STREAMS],
    i_valid:                u1[NUM_STREAMS],
    o_valid:                u1[NUM_STREAMS],
    select:                 u32[NUM_STREAMS]   
) -> uN[96][NUM_STREAMS] {
    for (olid, result): (u32, uN[96][NUM_STREAMS]) in u32:0..NUM_STREAMS {
        let new_result = if (o_valid[olid] && i_valid[select[olid]]) {update(result, olid, payload[select[olid]])} else {result};
        (new_result)
    }(zero!<uN[96][NUM_STREAMS]>())
}


#[test]
fn crossbar_test() {
    // two stream example
    let input: uN[96][2] = [u32: 0 ++ u32: 0 ++ u32: 1, u32: 0 ++ u32: 0 ++ u32: 2];
    let input_valid: u1[2] = [u1: 1, u1: 0];
    let output_valid: u1[2] = [u1: 1, u1: 1];
    let select: u32[2] = [u32: 1, u32: 0]; 
    let test_output: uN[96][2] = crossbar<u32: 2>(input, input_valid, output_valid, select);
    trace_fmt!("{:0x}", test_output);
}