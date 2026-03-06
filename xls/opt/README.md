The changes used to maximize the throughput/latency of the design
- modeled the IO of the memories and banks to be 1 cycle
- put skid puffer on sfcore and sf
- my sf_core was incorrect and draining phase ignored resent payloads, fixed that
- (minor) my testbench was wrong and assumed addr and payload werent sent at the same time (addr first, then payload).
    - i should make these a struct to ensure that they are sent at the same time (and all addr payload's for that matter)


(as an aside) debugging methods
- trace_fmt! a signal to figure out the wire name after codegen