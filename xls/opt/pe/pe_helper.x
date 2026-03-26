// IN FLIGHT WRITE QUEUE FORMAT
//           [MSB.....................................LSB]
// PAYLOAD:  [ u2 cmd ][ u30 row index ][ s32 data value ]
// cmd just transmit valid or not but is u2 since row index
// is capped at u30


// returns the most up to date base if its in the queue,
// with the head being the top priority. If no valid
// element is found, returns the given base (which is the memfetched one)
pub fn priority_grab<
    QUEUE_DEPTH: u32
>(
    input_queue:        uN[64][QUEUE_DEPTH],
    target_addr:        u30,
    mem_base:           u32
 ) -> u32 {
    (for (idx, base) : (u32, u32) in u32:0..QUEUE_DEPTH{
        let rev_idx = QUEUE_DEPTH - u32: 1 - idx;
        let match_pred = input_queue[rev_idx][62+:u2] == u2: 1 && input_queue[rev_idx][32+:u30] == target_addr;
        let n_base = if (match_pred) { input_queue[rev_idx][0+:u32] } else { base };
        (n_base)
    }(mem_base))
}

pub fn push_front<
    QUEUE_DEPTH: u32
>(
    input_queue:        uN[64][QUEUE_DEPTH],
    update_element:             uN[64]   
) -> uN[64][QUEUE_DEPTH] {
    (for (idx, queue) : (u32, uN[64][QUEUE_DEPTH]) in u32:0..QUEUE_DEPTH{
        let element = if (idx == u32: 0) { update_element } else { input_queue[idx - u32: 1] };
        let n_queue = update(queue, idx, element);
        (n_queue)
    }(zero!<uN[64][QUEUE_DEPTH]>()))
}

pub struct StreamAddr {
    read_or_write: u1,
    commands: u2,
    addr: u29,
    write_pld:  u32,
    matrix_val: u32,
    vector_val: u32,
}

pub struct StreamPayload {
    commands: u2,
    addr: u30,
    matrix_val: u32,
    vector_val: u32,
    mem_base: u32 // aka din
}