My first, "ideal" implementation of Hisparse in XLS. Run the command `make ideal` in the repo root to simulate. However, this is not able to generate correct verilog for the following reasons:

# Problems
- Tokens cannot flow through match/if arms: [discussion](https://github.com/google/xls/discussions/3736#discussioncomment-15642695)
- Cannot specify multiple operations per channel due to inability to specify FIFO configuration: [discussion](https://github.com/google/xls/discussions/3768)
- Internal proc state transitions are not ordered with respect to external proc IO operations
    - The matrix loader is a good example of this. The changing of the state.0 variable, aka the current state of the proc, occurs independently of the completions of the IO operations described in each "state" (such as the sending and receiving of the payload index and payload respectively). In practice when modeling non fully pipelined memories, the IO operations lag behind the state transitions, causing the IO operations to fire with incorrect data or at incorrect times. 
    - This is likely a misunderstanding on my part of the programming model.
- Sending/receiving on multiple channels with the same token does not imply the generated verilog will send/receive at the same time.
    - The arbiter/arbiter_wrapper is a good example of this. Since it uses recv_non_blocking, payloads must be sent in sync to be correct (the proc is latency sensitive). However, the shuffler_core sending the payloads, when generated into verilog, may not send the arbiter inputs at the same time, leading to dropped payloads.
- Cannot instantiate parametric procs with cross-activation tokens: [discussion](https://github.com/google/xls/issues/2039)


My tests are likely not expressive enough to catch some of these issues, and perhaps more effective tests that reflect the concurrent nature of hardware (on the XLS test-proc side) would have caught said issues earlier.