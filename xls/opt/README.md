The real optimization technique:
- basically "put each independently advancing blocking frontier in its own proc" implies addr sending procs must be separate from payload receiving procs. 
    - from what i understand, recv non-blocking doesnt break this invariant (but is non KPN style). Regardless, this may mean the shuffler core can be II 1 as well!
    - this would imply i use both approaches, the KPN split and Non-KPN monolothic (probably will still need to extract streaming shuffler core maybe?)

As a result of this optimization technique
- ml_send and ml_recv split such that ml_send can send addresses quickly, ml_recv only has a single frontier to accumulate values with at an II of 1
- sf was deleted, sf_core combined with a generic syncer that syncs SOD tokens replaced it, and arbiter modified to pass through commands for the following reasons:
    - SF originally arbitrated the incoming ml_recv stream, sending command tokens straight to output and syncing incoming SOD tokens, otherwise sending ml_recv stream to sfcore
    - By nature of the SF being a "wrapper" around the sfcore + arbiter, the SF had to, in its streaming state, 1) receive from the ml_recv stream 2) send to the sfcore 3) receive from the sfcore 4) send to the output stream
    - thus, in streaming, there are 2 receive frontiers, limiting the II to 2 for the sf + sfcore + arb combination.
    - Also this arbitration is just quite complicated to flatten into a single activation proc
    - Thus, sf's behavior was replaced with modules of II 1 and modifications to the hisparse arch.
        - Specifically, sfcore + arbiter is the only shuffle unit remaining (both with single cycle activations at II: 1), arbiter was modified to pass through commands to enable deletion of sf, and generic syncer restores the SOD syncing functionality that sf originally did.
        - note the SOD syncer is only necessary if payloads from ml_recv stream are unsynced somehow (uneven pipelining /w registers)

Minor changes used to maximize the throughput/latency of the design
- modeled the IO of the memories and banks to be 1 cycle
- put skid puffer on sfcore and sf
- my sf_core was incorrect and draining phase ignored resent payloads, fixed that
- (minor) my testbench was wrong and assumed addr and payload werent sent at the same time (addr first, then payload).
    - i should make these a struct to ensure that they are sent at the same time (and all addr payload's for that matter)

(as an aside) debugging methods
- trace_fmt! a signal to figure out the wire name after codegen