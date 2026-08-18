# Parameterized Asynchronous FIFO (CDC Design)

This repository contains the RTL implementation of a robust, fully parameterized Asynchronous FIFO in Verilog, designed to facilitate reliable, high-speed data transfer between independent read and write clock domains.

## Features & Implementation Highlights
- **Metastability Mitigation**: Pointers are converted to **Gray code** before being passed through double-register (2-stage) synchronizers to safely cross clock domains.
- **Glitch-Free Flag Logic**: 
  - `wfull` asserts when the write pointer catches up to the synchronized read pointer (detected via inverted MSBs).
  - `rempty` asserts when the read pointer matches the synchronized write pointer.
- **Advanced Flow Control**: Added parameterized `almost_full` and `almost_empty` threshold flags to support backpressure and pipeline pacing.
- **Fill Level Tracking**: Includes real-time `rfill_count` to monitor FIFO occupancy from the read domain perspective.
- **Dual-Port Memory**: Leverages independent read/write ports to prevent structural hazards during simultaneous accesses.

## Verification & Self-Checking Testbench
The included testbench (`FIFO_tb.v`) is designed for rigorous verification:
- **Golden Reference Queue**: Uses an internal SystemVerilog queue to self-check data integrity.
- **Boundary Condition Testing**: Automatically tests back-to-back operations, full recovery, empty recovery, and burst traffic under varying read/write frequency ratios.
- **Waveform Dump**: Automatically generates `.vcd` files for analysis in GTKWave or Vivado.

## Directory Structure
```
├── Verilog_Code/
│   ├── FIFO.v             # Top-level wrapper
│   ├── FIFO_memory.v      # Dual-port RAM module
│   ├── two_ff_sync.v      # 2-stage flip-flop synchronizer
│   ├── rptr_empty.v       # Read pointer, empty & almost_empty logic
│   ├── wptr_full.v        # Write pointer, full & almost_full logic
│   └── FIFO_tb.v          # Self-checking testbench
└── Assets/                # RTL Schematics and Waveforms
```

## How to Simulate (Vivado / Icarus Verilog)
1. Add all files in `Verilog_Code/` to your simulator.
2. Set `FIFO_tb.v` as the top-level simulation module.
3. Run simulation. The self-checking testbench will automatically print `SUCCESS` or `ERROR` for data integrity checks.
4. View the generated `fifo_waves.vcd` for signal analysis.

## References
- Core CDC synchronization architecture inspired by Cliff Cummings' SNUG papers.
