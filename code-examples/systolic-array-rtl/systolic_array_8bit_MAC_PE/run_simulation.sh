#!/bin/bash

# Script to run the traditional systolic array testbench
# Requires Synopsys VCS to be installed

echo "=========================================="
echo "Traditional Systolic Array Simulation"
echo "=========================================="
echo ""

# Check if VCS is available
if ! command -v vcs &> /dev/null; then
    echo "ERROR: VCS not found!"
    echo "Please ensure Synopsys VCS is installed and in your PATH"
    echo "You may need to source the VCS setup script, e.g.:"
    echo "  source /path/to/vcs/setup.sh"
    exit 1
fi

# Compile the design with VCS
echo "Compiling Verilog files with VCS..."
vcs -full64 -debug_access+all -sverilog \
    traditional_mac.v \
    traditional_systolic.v \
    traditional_systolic_tb.v \
    -o simv

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "Compilation successful!"
echo ""

# Run the simulation
echo "Running simulation..."
echo ""
./simv

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
    echo "View with: verdi -ssf traditional_systolic_tb.vcd (for Verdi)"
    echo ""
fi

# Note about waveform files
echo "Note: The testbench generates VCD files by default"
echo "For VPD format, add -debug_access+all+vpd to vcs compilation"
echo "Use DVE (dve -vpd file.vpd) or Verdi (verdi -ssf file.vcd) to view waveforms"
echo ""

echo "Simulation files:"
ls -lh simv traditional_systolic_tb.vcd 2>/dev/null || echo "Simulation binary created"
