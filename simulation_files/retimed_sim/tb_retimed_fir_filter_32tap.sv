// Verilog File I/O Testbench for ECG Denoising FIR Filter
`timescale 1ns / 1ps

module tb_fir_file_io;

    // Testbench Signals
    reg                     clk;
    reg                     rst_n;
    reg                     valid_in;
    reg  signed [7:0]       x_in;
    reg                     coeff_reload;
    reg  signed [255:0]     coeff_in;
    wire                    valid_out;
    wire signed [15:0]      y_out;

    // File Descriptors
    integer file_in;
    integer file_out;
    integer scan_status;
    integer sample_val;
    integer in_sample_count;
    integer out_sample_count;

    // Device Under Test (DUT)
    retimed_fir_filter_32tap dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .valid_in    (valid_in),
        .x_in        (x_in),
        .coeff_reload(coeff_reload),
        .coeff_in    (coeff_in),
        .valid_out   (valid_out),
        .y_out       (y_out)
    );

    // 100 MHz Simulation Clock (10 ns period)
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Output Logger Process (Synchronous capture on valid_out)
    always @(posedge clk) begin
        if (rst_n && valid_out) begin
            $fdisplay(file_out, "%d", y_out);
            out_sample_count = out_sample_count + 1;
        end
    end

    // Input Stimulus Process
    initial begin
        // Initialize Control
        rst_n            = 1'b0;
        valid_in         = 1'b0;
        x_in             = 8'sd0;
        coeff_reload     = 1'b0;
        coeff_in         = 256'd0;
        in_sample_count  = 0;
        out_sample_count = 0;

        // Open Files
        file_in = $fopen("ecg_noisy_input.txt", "r");
        if (file_in == 0) begin
            $display("[FATAL ERROR]: Could not open 'ecg_noisy_input.txt' for reading!");
            $finish;
        end

        file_out = $fopen("ecg_denoised_output.txt", "w");
        if (file_out == 0) begin
            $display("[FATAL ERROR]: Could not open 'ecg_denoised_output.txt' for writing!");
            $fclose(file_in);
            $finish;
        end

        $display("================================================================");
        $display("STARTING FILE I/O ECG DENOISING SIMULATION");
        $display("================================================================");

        // Reset Pulse
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);

        // Read and Feed Data
        while (!$feof(file_in)) begin
            scan_status = $fscanf(file_in, "%d\n", sample_val);
            if (scan_status == 1) begin
                @(posedge clk);
                valid_in <= 1'b1;
                x_in     <= sample_val[7:0];
                in_sample_count = in_sample_count + 1;
            end
        end

        // End of input stream -> Flush pipeline
        @(posedge clk);
        valid_in <= 1'b0;
        x_in     <= 8'sd0;

        // Allow remaining samples to exit retiming pipeline (5 latency cycles)
        repeat (20) @(posedge clk);

        // Close Files
        $fclose(file_in);
        $fclose(file_out);

        $display("================================================================");
        $display("SIMULATION COMPLETE SUMMARY:");
        $display(" - Total Input Samples Processed  : %0d", in_sample_count);
        $display(" - Total Filtered Samples Written : %0d", out_sample_count);
        $display(" - Output written to file         : 'ecg_denoised_output.txt'");
        $display("================================================================");
        $finish;
    end

endmodule