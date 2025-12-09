#!/bin/bash

# Script to run the traditional systolic array testbench
# Requires iverilog (Icarus Verilog) to be installed

echo "=========================================="
echo "Traditional Systolic Array Simulation"
echo "=========================================="
echo ""

# Check if iverilog is available
if ! command -v iverilog &> /dev/null; then
    echo "ERROR: iverilog not found!"
    echo "Please install Icarus Verilog:"
    echo "  Ubuntu/Debian: sudo apt-get install iverilog"
    echo "  MacOS: brew install icarus-verilog"
    echo "  Fedora: sudo dnf install iverilog"
    exit 1
fi

# Compile the design
echo "Compiling Verilog files..."
iverilog -o traditional_systolic_sim \
    traditional_mac.v \
    traditional_systolic.v \
    traditional_systolic_tb.v

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "Compilation successful!"
echo ""

# Run the simulation
echo "Running simulation..."
echo ""
vvp traditional_systolic_sim

if [ $? -ne 0 ]; then
    echo "ERROR: Simulation failed!"
    exit 1
fi

echo ""
echo "=========================================="
echo "Simulation completed successfully!"
echo "=========================================="
echo ""

# Check if VCD file was generated
if [ -f "traditional_systolic_tb.vcd" ]; then
    echo "Waveform file generated: traditional_systolic_tb.vcd"
    echo "View with: gtkwave traditional_systolic_tb.vcd"
    echo ""
fi

# Clean up simulation binary if desired
# Uncomment the following line to auto-delete the simulation binary
# rm -f traditional_systolic_sim

echo "Simulation files:"
ls -lh traditional_systolic_sim traditional_systolic_tb.vcd 2>/dev/null || echo "No output files found"
