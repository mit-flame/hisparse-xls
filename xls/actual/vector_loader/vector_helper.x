// takes in one packed vector payload, makes vector payload one
// PAYLOAD FORMAT
//              [MSB......................................................LSB]
// TYPE HBM:    [ s32 data value ] * NUM_STREAMS
// TYPE ONE:    [ u2 cmd ][ u30 index ][ s32 data value ] * NUM_STREAMS
// TYPE TWO:    [ u2 cmd ][ u30 index ][ s32 data value ] <-- there will be NUM_STREAMS of these
// TYPE THREE:  [ u2 cmd ][ u30 index (row) ][ s32 vector val ][ s32 matrix val ]
pub fn payload_converter<
    NUM_STREAMS: u32,
    PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}
>(
    payload_type_hbm_i:     u32[NUM_STREAMS],
    current_index:          u32,
    command:                u2
) -> uN[PAYLOAD_ONE_BITWIDTH]
{
    (command ++ (current_index as u30) ++ (payload_type_hbm_i as uN[NUM_STREAMS << u32: 5]))
}

// technically its a payload converter from one to two
pub fn payload_extractor<
    NUM_STREAMS: u32,
    PAYLOAD_ONE_BITWIDTH: u32 = { ((NUM_STREAMS + u32: 1) << 5)}
>(
    vector_payload_one:     uN[PAYLOAD_ONE_BITWIDTH],
    index:                  u32
) -> uN[64]
{
    let indx = vector_payload_one[(PAYLOAD_ONE_BITWIDTH - u32: 32)+:u30]*(NUM_STREAMS as u30) + (index as u30);
    (vector_payload_one[(PAYLOAD_ONE_BITWIDTH - u32: 2)+:u2] ++ indx ++ vector_payload_one[(index << 5)+:u32])
}

pub fn unpack_payload_two(
    vector_payload_two:     uN[64]
) -> (u2, u30, u32)
{
    (vector_payload_two[62+:u2], vector_payload_two[32+:u30], vector_payload_two[0+:u32])
}

// makes a payload type three
pub fn matrix_vector_payload_merge(
    matrix_payload_two:     uN[96],
    vector_value:           u32
) -> uN[96]
{
    (matrix_payload_two[94+:u2] ++ matrix_payload_two[32+:u30] ++ vector_value ++ matrix_payload_two[0+:u32])
}

pub fn unpack_matrix_payload_two(
    matrix_payload_two:     uN[96]
) -> (u2, u30, u32, u32)
{
    (matrix_payload_two[94+:u2], matrix_payload_two[64+:u30], matrix_payload_two[32+: u32], matrix_payload_two[0+:u32])
}