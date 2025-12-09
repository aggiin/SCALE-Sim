# Traditional Systolic Array Testbench

This directory contains a Verilog testbench for the traditional systolic array implementation.

## Files

- `traditional_mac.v` - Processing Element (PE) module with MAC (Multiply-Accumulate) unit
- `traditional_systolic.v` - Parameterizable systolic array with configurable rows and columns
- `traditional_systolic_tb.v` - Testbench for matrix multiplication verification
- `run_simulation.sh` - Shell script to compile and run the simulation

## Testbench Description

The testbench (`traditional_systolic_tb.v`) performs a complete matrix multiplication using the systolic array:

- **Array Configuration**: 4x4 systolic array (configurable via parameters)
- **Word Size**: 16 bits
- **Operation**: Matrix multiplication C = A × B
- **Test Matrices**: 
  - Matrix A: 4×4 matrix with simple integer values
  - Matrix B: 4×4 identity matrix for easy verification
  - Expected Result C: Should equal Matrix A

### Features

1. **Systolic Data Flow**: Implements proper wave-front scheduling for feeding data into the array
2. **Clock Generation**: 10ns clock period
3. **Reset Logic**: Proper initialization sequence
4. **Result Collection**: Collects outputs from bottom and right buses
5. **Expected Result Calculation**: Software calculation for verification
6. **Waveform Dump**: Generates VCD file for waveform viewing

## How to Run

### Prerequisites

This testbench is designed to run with Synopsys VCS. Ensure you have:

- **Synopsys VCS** installed and properly licensed
- VCS setup script sourced (e.g., `source /path/to/vcs/setup.sh`)
- DVE (Discovery Visual Environment) or Verdi for waveform viewing (optional)

### Running the Simulation

1. Make the simulation script executable:
```bash
chmod +x run_simulation.sh
```

2. Run the simulation:
```bash
./run_simulation.sh
```

### Alternative: Manual Compilation and Execution with VCS

```bash
# Compile with VCS (generates VCD by default)
vcs -full64 -debug_access+all -sverilog traditional_mac.v traditional_systolic.v traditional_systolic_tb.v -o simv

# Run simulation
./simv

# View waveforms with Verdi (for VCD files)
verdi -ssf traditional_systolic_tb.vcd &

# Or compile with VPD format for DVE
vcs -full64 -debug_access+all+vpd -sverilog traditional_mac.v traditional_systolic.v traditional_systolic_tb.v -o simv
./simv
dve -vpd vcdplus.vpd &
```

### Using Other Simulators

If you prefer to use other simulators:

**Icarus Verilog (open-source):**
```bash
iverilog -o sim traditional_mac.v traditional_systolic.v traditional_systolic_tb.v
vvp sim
gtkwave traditional_systolic_tb.vcd
```

**Cadence Xcelium:**
```bash
xrun traditional_mac.v traditional_systolic.v traditional_systolic_tb.v
```

**Mentor ModelSim/Questa:**
```bash
vlog traditional_mac.v traditional_systolic.v traditional_systolic_tb.v
vsim -c work.traditional_systolic_tb -do "run -all; quit"
```

## Understanding the Output

The testbench will display:

1. **Input Matrices**: Shows Matrix A and Matrix B
2. **Expected Result**: Software-calculated result of A × B
3. **Systolic Array Outputs**: Values from bottom_out_bus and right_out_bus

### Important Notes

- The systolic array operates in a pipelined manner with data flowing through the array
- Results appear at output buses after multiple clock cycles due to pipeline depth
- The control signals (`ctl_stat_bit_in`, `ctl_dummy_fsm_op2_select_in`, `ctl_dummy_fsm_out_select_in`) configure the dataflow mode
- Current testbench uses Output Stationary (OS) mode configuration

### Waveform Analysis

For detailed analysis, view the waveform file with VCS tools:

```bash
# Using Verdi (recommended for VCD files)
verdi -ssf traditional_systolic_tb.vcd &

# Using DVE (if VPD format is generated)
# Note: Add '-debug_access+all+vpd' to vcs compilation to generate VPD
dve -vpd vcdplus.vpd &
```

For other simulators, use their respective waveform viewers (e.g., GTKWave for open-source).

Recommended signals to monitor:
- `clk`, `rst` - Clock and reset
- `left_in_bus`, `top_in_bus` - Input data buses
- `bottom_out_bus`, `right_out_bus` - Output data buses
- Internal PE signals (expand the `dut` hierarchy)

## Customization

You can modify the testbench parameters to test different configurations:

```verilog
parameter ROWS = 4;        // Number of rows
parameter COLS = 4;        // Number of columns  
parameter WORD_SIZE = 16;  // Bit width of operands
```

You can also modify the test matrices in the `initialize_matrices` task to test different matrix multiplication scenarios.

## Dataflow Modes

The systolic array supports different dataflow modes:
- **Output Stationary (OS)**: Accumulator stays in PE
- **Weight Stationary (WS)**: Weights stay stationary
- **Input Stationary (IS)**: Input activations stay stationary

Configure mode using the control signals. The current testbench is set up for OS mode.

## Troubleshooting

If you encounter issues:

1. **Compilation errors**: Ensure all three Verilog files are in the same directory
2. **Simulation timeout**: Increase the timeout value in the testbench
3. **Unexpected results**: Check control signal configuration and data feeding timing
4. **Missing VCD file**: Ensure `$dumpfile` and `$dumpvars` statements are not commented out

## Further Reading

- See the parent directory README for more information about the systolic array architecture
- Refer to academic papers on systolic arrays for understanding dataflow modes
- Check the SCALE-Sim documentation for integration with the simulator
