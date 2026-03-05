pub fn matrix_loader_initial_state<
    NUM_STREAMS: u32
>() -> u32[NUM_STREAMS] {
    for (idx, state) : (u32, u32[NUM_STREAMS]) in u32:0..NUM_STREAMS{
        let new_state = update(state, idx, idx);
        (new_state)
    }(zero!<u32[NUM_STREAMS]>())
}