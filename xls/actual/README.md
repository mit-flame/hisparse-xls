The first XLS implementation of hisparse that generated simulation correct verilog. The following changes were made:

# Modifications
- solved by separating send/recv from state logic, in turn breaking states down until there was exactly only sends or only receives (greatly increased the number of states)
- solved by referencing channels once in the activation
- solved by attaching IO constraint to channels that interacted with external memories, reducing the throughput of the procs and slowing down the internal state transitions
- solved by using a struct to group statically tied data into one send/recv
- solved using makefile workaround (wasnt that big of a problem to begin with)

