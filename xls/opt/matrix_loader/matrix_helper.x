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
pub fn payload_converter<
    NUM_STREAMS: u32
>(
    payload_type_one_i:     uN[64],
    current_row_index:      u32,
    command:                u2
) -> uN[96]
{
    let index = payload_type_one_i[32+:u32];
    let data = payload_type_one_i[0+:u32];
    let row = 
    if (index == all_ones!<u32>()){
        current_row_index + data * NUM_STREAMS
    }
    else {
        current_row_index
    };
    (command ++ (index as u30) ++ row ++ data)
}

// if i put getters here this can serve as the centralized
// authority on the payload format, aka make it an opaque type
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