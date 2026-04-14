This example represents the failure to flow match arms backwards I encountered when trying to codegen my procs. Most of the states in my proc state machines involved IO operations that produced tokens, thus this bug required the separation of IO operations from state (as a conservative approach to ensure codegen capabilities)

The relevant discussion post is here: [discussion](https://github.com/google/xls/discussions/3736#discussioncomment-15642695)

Currently bugged in XLS version: 13ac505ae3f54460c4124757598344ecc319cd6e
