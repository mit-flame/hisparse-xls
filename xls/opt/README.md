# Applied Optimization Techniques

## Frontier Splitting
The idea here is to put each independently advancing blocking frontier in its own proc. A blocking frontier is defined as a blocking receive (as opposed to a non blocking receive) and any number of sends. Typically this implies that the process of conditionally sending a read/write request to external memory must be broken up into 2+ procs as there is likely 2+ receives sequentially there. This technique led to the following changes in the code:

1) Matrix Loader:
- ml_send and ml_recv split such that ml_send can send addresses quickly, ml_recv only has a single frontier to accumulate values with at an II of 1
- the commands were pipelined alongside the memory requests to avoid communication between ml_send and ml_recv

2) Shuffler:
- By nature of the SF being a "wrapper" around the sfcore + arbiter, the SF had to, in its streaming state, 1) receive from the ml_recv stream 2) send to the sfcore 3) receive from the sfcore 4) send to the output stream
    - thus, in streaming, there are 2 receive frontiers, limiting the II to 2 for the sf + sfcore + arb combination.
- Sf's behavior was replaced with modules of II 1 and modifications to the hisparse arch.
        - Specifically, sfcore + arbiter is the only shuffle unit remaining (both with single cycle activations at II: 1), arbiter was modified to pass through commands to enable deletion of sf, and generic syncer restores the SOD syncing functionality that sf originally did.

3) Vector Buffer Access Unit:
- Split original vector buffer acess unit into a vba_send and vba_recv
- pipelined key information alongside memory requests to avoid communication between vba_send and vba_recv

3) Processing Engine:
- Split original processing engine into pe_send and pe_recv
- Unrelated to memory port multiplexing below, also made memory dual port (original Hisparse arch made same assumption and it makes sense given the Read After Write considerations in the original paper)
- pipelined key information alongside memory requests in the same way the vector buffer access unit did

## Memory Port Multiplexing
XLS at this moment cannot codegen procs that make multiple IO operations *on the same channel* in a given activation. As mentioned in the "actual" implementation, this limitation was solved by conditioning the firing of an IO operation on a channel using states. However, this approach naturally leads to a higher II than desired. To mitigate this issue without making exceedingly complicated state machines, I decided to make multiple channels that refer to the same memory port, and create arbiters in XLS that merge these multiple channel references. As long as only one channel has valid data at a given moment (which is always true in my use case), this merging is correct and allows the external memory to be modeled with a single port. This technique led to the following changes in the code:

1) Matrix Loader: 
- The matrix loader addr channel was turned into a metadata_addr and streaming_addr channel (and correspondingly the memory result channel was split into a metadata result and streaming result channel). Now metadata requests (at the beginning of partitions) can be split from the streaming requests
- arbiters were created for both the address sending channels as well as the payload receiving channel (since there are two "tracks" of memory requests: metadata and streaming)

2) Vector Buffer Access Unit:
- The vector buffer access units bank address channel was split into a loading_addr and streaming_addr channel. Now loading requests can be split from the streaming requests.
- an arbiter was created for only the address sending channels (since loading_addr only wrote to the memory, never read from it)

3) Processing Engine:
- Using the processing engine as a way to stress test this idea even more, I made three addresses: clearing_addr, streaming_addr and result_addr. All are mutually exclusive, thus the arbiter connected all of them to a unified addr which sent unified plds to the pe_recv unit.

# Other Architecture Changes
These changes just made it easier to optimize HiSparse in XLS

1) Separation of Token Syncing from Main Proc Logic:
- Adding logic in my procs to sync incoming tokens made the statemachine needlessly complicated, so I generalized the logic into procs that can be attached anywhere in the stream to ensure modules see synced streams at all times.

Minor changes
- modeled the IO of the memories and banks to be 1 cycle
- put skid puffer on sfcore and sf
- my sf_core was incorrect and draining phase ignored resent payloads, fixed that
- (minor) my testbench was wrong and assumed addr and payload werent sent at the same time (addr first, then payload).
    - i should make these a struct to ensure that they are sent at the same time (and all addr payload's for that matter)

(as an aside) debugging methods
- trace_fmt! a signal to figure out the wire name after codegen

Finally, this could be optimized further by making the prologue and epiloge faster, however, I focused on streaming as that is 99% of the time taken in this architecture. It is very likely that these techniques could speed up the prologue and epiloge as well.