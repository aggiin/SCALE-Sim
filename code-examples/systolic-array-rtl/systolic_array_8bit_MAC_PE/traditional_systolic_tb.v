`timescale 1ns / 1ps

module traditional_systolic_tb;

    // Parameters - using smaller array for easier verification
    parameter ROWS = 4;
    parameter COLS = 4;
    parameter WORD_SIZE = 16;
    parameter CLOCK_PERIOD = 10;
    
    // Testbench signals
    reg clk;
    reg rst;
    reg ctl_stat_bit_in;
    reg ctl_dummy_fsm_op2_select_in;
    reg ctl_dummy_fsm_out_select_in;
    
    reg [ROWS * WORD_SIZE - 1: 0] left_in_bus;
    reg [COLS * WORD_SIZE - 1: 0] top_in_bus;
    wire [COLS * WORD_SIZE - 1: 0] bottom_out_bus;
    wire [ROWS * WORD_SIZE - 1: 0] right_out_bus;
    
    // Test matrices
    // Matrix A (4x4) - fed from left
    reg [WORD_SIZE-1:0] matrix_a [0:ROWS-1][0:COLS-1];
    // Matrix B (4x4) - fed from top
    reg [WORD_SIZE-1:0] matrix_b [0:ROWS-1][0:COLS-1];
    // Result matrix C (4x4)
    reg [WORD_SIZE-1:0] matrix_c [0:ROWS-1][0:COLS-1];
    
    integer i, j, k;
    integer cycle_count;
    
    // Instantiate the systolic array
    traditional_systolic #(
        .ROWS(ROWS),
        .COLS(COLS),
        .WORD_SIZE(WORD_SIZE)
    ) dut (
        .clk(clk),
        .rst(rst),
        .ctl_stat_bit_in(ctl_stat_bit_in),
        .ctl_dummy_fsm_op2_select_in(ctl_dummy_fsm_op2_select_in),
        .ctl_dummy_fsm_out_select_in(ctl_dummy_fsm_out_select_in),
        .left_in_bus(left_in_bus),
        .top_in_bus(top_in_bus),
        .bottom_out_bus(bottom_out_bus),
        .right_out_bus(right_out_bus)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end
    
    // Initialize test matrices
    task initialize_matrices;
        begin
            // Initialize Matrix A (simple values for easy verification)
            // A = [1 2 3 4]
            //     [5 6 7 8]
            //     [1 1 1 1]
            //     [2 2 2 2]
            matrix_a[0][0] = 16'd1; matrix_a[0][1] = 16'd2; matrix_a[0][2] = 16'd3; matrix_a[0][3] = 16'd4;
            matrix_a[1][0] = 16'd5; matrix_a[1][1] = 16'd6; matrix_a[1][2] = 16'd7; matrix_a[1][3] = 16'd8;
            matrix_a[2][0] = 16'd1; matrix_a[2][1] = 16'd1; matrix_a[2][2] = 16'd1; matrix_a[2][3] = 16'd1;
            matrix_a[3][0] = 16'd2; matrix_a[3][1] = 16'd2; matrix_a[3][2] = 16'd2; matrix_a[3][3] = 16'd2;
            
            // Initialize Matrix B (simple values)
            // B = [1 0 0 0]
            //     [0 1 0 0]
            //     [0 0 1 0]
            //     [0 0 0 1]
            matrix_b[0][0] = 16'd1; matrix_b[0][1] = 16'd0; matrix_b[0][2] = 16'd0; matrix_b[0][3] = 16'd0;
            matrix_b[1][0] = 16'd0; matrix_b[1][1] = 16'd1; matrix_b[1][2] = 16'd0; matrix_b[1][3] = 16'd0;
            matrix_b[2][0] = 16'd0; matrix_b[2][1] = 16'd0; matrix_b[2][2] = 16'd1; matrix_b[2][3] = 16'd0;
            matrix_b[3][0] = 16'd0; matrix_b[3][1] = 16'd0; matrix_b[3][2] = 16'd0; matrix_b[3][3] = 16'd1;
            
            // Initialize result matrix to zero
            for (i = 0; i < ROWS; i = i + 1) begin
                for (j = 0; j < COLS; j = j + 1) begin
                    matrix_c[i][j] = 16'd0;
                end
            end
        end
    endtask
    
    // Calculate expected result (software matrix multiplication)
    task calculate_expected_result;
        begin
            for (i = 0; i < ROWS; i = i + 1) begin
                for (j = 0; j < COLS; j = j + 1) begin
                    matrix_c[i][j] = 16'd0;
                    for (k = 0; k < COLS; k = k + 1) begin
                        matrix_c[i][j] = matrix_c[i][j] + (matrix_a[i][k] * matrix_b[k][j]);
                    end
                end
            end
            
            $display("\n=== Expected Result Matrix C = A * B ===");
            for (i = 0; i < ROWS; i = i + 1) begin
                $display("Row %0d: %4d %4d %4d %4d", i, 
                    matrix_c[i][0], matrix_c[i][1], matrix_c[i][2], matrix_c[i][3]);
            end
            $display("");
        end
    endtask
    
    // Display matrices
    task display_input_matrices;
        begin
            $display("\n=== Input Matrix A (fed from left) ===");
            for (i = 0; i < ROWS; i = i + 1) begin
                $display("Row %0d: %4d %4d %4d %4d", i, 
                    matrix_a[i][0], matrix_a[i][1], matrix_a[i][2], matrix_a[i][3]);
            end
            
            $display("\n=== Input Matrix B (fed from top) ===");
            for (i = 0; i < ROWS; i = i + 1) begin
                $display("Row %0d: %4d %4d %4d %4d", i, 
                    matrix_b[i][0], matrix_b[i][1], matrix_b[i][2], matrix_b[i][3]);
            end
            $display("");
        end
    endtask
    
    // Feed data in systolic manner (wave-front scheduling)
    task feed_systolic_data;
        integer cycle;
        integer row, col;
        begin
            // Total cycles needed = ROWS + COLS + processing time
            // For systolic array: each element enters at different times
            // Proper systolic timing: A[row][col] enters row 'row' at cycle (row + col)
            // and B[row][col] enters column 'col' at cycle (row + col)
            for (cycle = 0; cycle < ROWS + COLS + ROWS + 5; cycle = cycle + 1) begin
                // Initialize buses to zero each cycle
                left_in_bus = {(ROWS * WORD_SIZE){1'b0}};
                top_in_bus = {(COLS * WORD_SIZE){1'b0}};
                
                // Feed Matrix A from left with proper systolic timing
                // Each row receives data at staggered times
                // A[row][col] is fed to row 'row' at cycle (row + col)
                for (row = 0; row < ROWS; row = row + 1) begin
                    for (col = 0; col < COLS; col = col + 1) begin
                        if (cycle == (row + col)) begin
                            left_in_bus[(row+1)*WORD_SIZE-1 -: WORD_SIZE] = matrix_a[row][col];
                        end
                    end
                end
                
                // Feed Matrix B from top with proper systolic timing
                // Each column receives data at staggered times
                // B[row][col] is fed to column 'col' at cycle (row + col)
                for (col = 0; col < COLS; col = col + 1) begin
                    for (row = 0; row < ROWS; row = row + 1) begin
                        if (cycle == (row + col)) begin
                            top_in_bus[(col+1)*WORD_SIZE-1 -: WORD_SIZE] = matrix_b[row][col];
                        end
                    end
                end
                
                @(posedge clk);
            end
        end
    endtask
    
    // Collect and display output
    task collect_output;
        integer out_row, out_col;
        integer sample_time;
        begin
            // For systolic array with proper wave-front scheduling:
            // - Data feeding takes ROWS + COLS - 1 cycles
            // - Results need additional ROWS + COLS cycles to fully propagate
            // - Total delay needed: ~2*(ROWS + COLS) cycles
            
            $display("\n=== Monitoring Outputs During Computation ===");
            
            // Sample outputs at different time points
            for (sample_time = 0; sample_time < 3; sample_time = sample_time + 1) begin
                repeat(ROWS + COLS) @(posedge clk);
                
                $display("\nSample at cycle %0d (time %0t):", sample_time, $time);
                $display("Bottom output bus (by column):");
                for (out_col = 0; out_col < COLS; out_col = out_col + 1) begin
                    $display("  Column %0d: %4d", out_col, 
                        $signed(bottom_out_bus[(out_col+1)*WORD_SIZE-1 -: WORD_SIZE]));
                end
                
                $display("Right output bus (by row):");
                for (out_row = 0; out_row < ROWS; out_row = out_row + 1) begin
                    $display("  Row %0d: %4d", out_row, 
                        $signed(right_out_bus[(out_row+1)*WORD_SIZE-1 -: WORD_SIZE]));
                end
            end
            
            $display("\n=== Final Output from Systolic Array ===");
            $display("Bottom output bus (by column):");
            for (out_col = 0; out_col < COLS; out_col = out_col + 1) begin
                $display("  Column %0d: %4d", out_col, 
                    $signed(bottom_out_bus[(out_col+1)*WORD_SIZE-1 -: WORD_SIZE]));
            end
            
            $display("\nRight output bus (by row):");
            for (out_row = 0; out_row < ROWS; out_row = out_row + 1) begin
                $display("  Row %0d: %4d", out_row, 
                    $signed(right_out_bus[(out_row+1)*WORD_SIZE-1 -: WORD_SIZE]));
            end
            $display("");
        end
    endtask
    
    // Main test sequence
    initial begin
        $display("\n========================================");
        $display("Traditional Systolic Array Testbench");
        $display("Matrix Multiplication: C = A * B");
        $display("Array Size: %0dx%0d", ROWS, COLS);
        $display("Word Size: %0d bits", WORD_SIZE);
        $display("========================================\n");
        
        // Initialize signals
        rst = 1;
        ctl_stat_bit_in = 0;
        ctl_dummy_fsm_op2_select_in = 0;
        ctl_dummy_fsm_out_select_in = 0;
        left_in_bus = {(ROWS * WORD_SIZE){1'b0}};
        top_in_bus = {(COLS * WORD_SIZE){1'b0}};
        cycle_count = 0;
        
        // Initialize test matrices
        initialize_matrices();
        display_input_matrices();
        calculate_expected_result();
        
        // Apply reset
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        
        $display("Starting systolic array computation...\n");
        
        // Configure for Output Stationary mode (OS)
        // stat_bit_in = 0 for OS mode
        ctl_stat_bit_in = 0;
        ctl_dummy_fsm_op2_select_in = 0;
        ctl_dummy_fsm_out_select_in = 1; // 1: output accumulator_reg, 0: output top_in_reg
        
        // Feed data in systolic manner
        feed_systolic_data();
        
        // Collect and display outputs
        collect_output();
        
        $display("\n=== Simulation Notes ===");
        $display("Configuration: Output Stationary (OS) mode");
        $display("  - ctl_stat_bit_in = 0");
        $display("  - ctl_dummy_fsm_op2_select_in = 0");
        $display("  - ctl_dummy_fsm_out_select_in = 1 (accumulator output)");
        $display("");
        $display("In OS mode with this configuration:");
        $display("  - Each PE computes: accumulator += left_in * top_in");
        $display("  - Results accumulate in each PE");
        $display("  - Output appears at bottom_out_bus after all data propagates");
        $display("");
        $display("For complete verification:");
        $display("  1. Check waveform viewer (VCS DVE, Verdi, or GTKWave)");
        $display("  2. Monitor internal PE accumulator_reg signals");
        $display("  3. Verify timing of data flow through the array");
        $display("  4. Results depend on proper systolic timing alignment");
        $display("========================================\n");
        
        // Finish simulation
        repeat(20) @(posedge clk);
        $display("Simulation completed at time %0t", $time);
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #(CLOCK_PERIOD * 1000);
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
    // Optional: Dump waveforms for viewing
    initial begin
        $dumpfile("traditional_systolic_tb.vcd");
        $dumpvars(0, traditional_systolic_tb);
    end
    
    // Monitor for debugging - tracks when outputs change
    integer monitor_cycle;
    initial begin
        monitor_cycle = 0;
        forever begin
            @(posedge clk);
            monitor_cycle = monitor_cycle + 1;
            // Uncomment below to see cycle-by-cycle output changes
            // if (bottom_out_bus != 0 || right_out_bus != 0) begin
            //     $display("Cycle %0d: bottom_out[0]=%0d, right_out[0]=%0d", 
            //              monitor_cycle, 
            //              $signed(bottom_out_bus[WORD_SIZE-1:0]),
            //              $signed(right_out_bus[WORD_SIZE-1:0]));
            // end
        end
    end

endmodule
