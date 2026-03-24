// only accepts ONE stream payload. So only ONE data, index pair (64 bits)
// PAYLOAD FORMAT
//           [MSB......................................................LSB]
// TYPE ONE: [ u32 col index ][ s32 data value ]
// TYPE TWO: [ u2 cmd ][ u30 col index ][ u32 row index ][ u32 data value ]
// if index is == MAX_VAL, this is a next row marker or padding, where
// the next row is calculated as adding data * NUM_STREAMS to current row.
// padding can be achieved by just having the data be 0 and index
// be MAX_VAL. When payload ones are padding, payload twos will be all
// zeroes

pub fn unpack_payload_one<
    NUM_STREAMS: u32
>(
    payload_type_one:        uN[64][NUM_STREAMS],
    stream_number:           u32
) -> (u32, u32){
    (payload_type_one[stream_number][32+:u32],payload_type_one[stream_number][0+:u32])
}

// make max value of array func
pub fn max_array<
    LENGTH: u32
>(
    array:              u32[LENGTH]
) -> u32 {
    for (idx, max) : (u32, u32) in u32:0..LENGTH {
        let new_max = if (array[idx] > max) { array[idx] } else { max };
        (new_max)
    }((u32: 0))
}

pub struct StreamAddr{
    addr: u32,
    commands: u2, // is this SOD, EOD, EOS or nothing
    message_type: u30 // is this a metadata req or a streaming req etc etc
}

pub struct StreamPayload<NUM_STREAMS: u32>{
    payload_type_one: uN[64][NUM_STREAMS],
    commands: u2,
    message_type: u30
}