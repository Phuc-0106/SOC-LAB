# Single-Cycle RISC-V (Lab3)

## How to run
On Windows PowerShell (from the project folder):
```
iverilog -g2012 -I . -o simv testbench.v DatapathSingleCycle.v gp1.v gp4.v gp8.v
vvp .\simv
```

- Simulation output and wave.vcd will be generated in the current directory.
- Memory is initialized from the `.hex` files referenced in the testbench.

## Change the test
Open `testbench.v` and set `test_case`:
- 1 = mem_test_add.hex
- 2 = mem_test_div.hex
- 3 = mem_test_load_store_jalr.hex
- 4 = mem_test_case4.hex

Example:
```verilog
integer test_case = 4; // select test case 4
```

Rebuild and run:
```
iverilog -g2012 -I . -o simv testbench.v DatapathSingleCycle.v gp1.v gp4.v gp8.v
vvp .\simv
```

## Notes
- `.hex` files must be clean hex data: one 8-hex-digit word per line, no comments.
- The “Not enough words” warning when loading `mem_initial_contents.hex` can be ignored; the testbench overwrites memory with the selected test afterward.