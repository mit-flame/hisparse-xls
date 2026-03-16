The changes used to maximize the throughput/latency of the design
- modeled the IO of the memories and banks to be 1 cycle
- put skid puffer on sfcore and sf
- my sf_core was incorrect and draining phase ignored resent payloads, fixed that
- (minor) my testbench was wrong and assumed addr and payload werent sent at the same time (addr first, then payload).
    - i should make these a struct to ensure that they are sent at the same time (and all addr payload's for that matter)
- basically "put each independently advancing blocking frontier in its own proc" implies addr sending procs must be separate from payload receiving procs. 
    - from what i understand, recv non-blocking doesnt break this invariant (but is non KPN style). Regardless, this may mean the shuffler core can be II 1 as well!
    - this would imply i use both approaches, the KPN split and Non-KPN monolothic (probably will still need to extract streaming shuffler core maybe?)


(as an aside) debugging methods
- trace_fmt! a signal to figure out the wire name after codegen