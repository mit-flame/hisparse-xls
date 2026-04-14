This example represents the failure to have multiple operations per channel due to an inability to specify a FIFO config that I encountered when trying to codegen my procs. As mentioned in the match arms in tokens bug, many of my procs' states have IO operations. Often times these IO operations are on the same IO channels. Thus I need the capability to describe multiple IO operations per channel activation. The consequence of this bug was again the separation of IO operations from state.

The relevant discussion post is here:[discussion](https://github.com/google/xls/discussions/3768)

Currently bugged in XLS version: 13ac505ae3f54460c4124757598344ecc319cd6e
