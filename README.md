# Requirements
- cocotb (made with 1.9.2)
- cocotb_bus
- verilator (made with 5.020)
- xls (using commit hash 13ac505ae3f54460c4124757598344ecc319cd6e)

# Installation
Update the xls paths in the makefile to attach to your XLS installation.

# How To Run
0) Ensure the above requirements are met on your system
1) run "make" in repo root to see available commands...
    1) simulation
        - "make ideal" simulates the ideal implementation in XLS' test framework using an integration test. Likewise, "make actual" and "make opt" simulate the conservative and optimize implementation respectively.
    2) codegen
        - "make clean" cleans the /hdl/ folder (preserving handwritten toplevel verilog files)
        - "make all" makes the entire design with constants specified at the top of the makefile. Pass in MODE=actual to generate the conservative implementation, or MODE=opt to generate the optimized implementation
3) To test HDL files with Cocotb, codegen either the actual or opt design using the above commands, and run "python single_cluster_actual" or "python single_cluster_opt" respectively

