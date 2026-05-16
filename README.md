# Requirements
- cocotb (made with 1.9.2)
- cocotb_bus
- verilator (made with 5.020)
- xls (using commit hash 13ac505ae3f54460c4124757598344ecc319cd6e)

# Installation
Update the xls paths in the makefile to attach to your XLS installation.

# Repository Setup
- /data/ holds matrices to pass into cocotb testbenches, as well as Xilinx/Vivado Coefficient files (*.coe) to prepopulate the BRAMs with particular matrix/vector values
- /hdl/ holds the handwritten verilog toplevel files as well as the codegenerated HDL
- /sim/ holds all the Cocotb simulation logic. /sim/* holds the cocotb testbenches for simulating the different HiSparse XLS versions as well as other miscellaneous tests and /sim/lib/ holds Cocotb helper classes and functions for procs and HiSparse modules
- /synth/ is a particular snapshot of the HiSparse design synthesized on Vivado
- /xls/ holds all of the DSLX source code, split into the ideal (first naive implementation), actual (second conservative implementation) and opt (optimized using split proc and channel multiplexing techniques) versions. These are further broken down into key modules within the HiSparse arch. /xls/thesis_examples/ hold bug examples for the particular XLS version used.

# How To Run
0) Ensure the above requirements are met on your system
1) run "make" in repo root to see available commands...
    1) simulation
        - "make ideal" simulates the ideal implementation in XLS' test framework using an integration test. Likewise, "make actual" and "make opt" simulate the conservative and optimize implementation respectively.
    2) codegen
        - "make clean" cleans the /hdl/ folder (preserving handwritten toplevel verilog files)
        - "make all" makes the entire design with constants specified at the top of the makefile. Pass in MODE=actual to generate the conservative implementation, or MODE=opt to generate the optimized implementation
3) To test HDL files with Cocotb, codegen either the actual or opt design using the above commands, and run "python single_cluster_actual" or "python single_cluster_opt" respectively

