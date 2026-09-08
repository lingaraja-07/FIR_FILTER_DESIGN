// Memory-Efficient Self-Checking Testbench for FPGA Fabric-Aware Arithmetic Units
// Optimized for fast compilation (< 3 sec) in Vivado XSim
`timescale 1ns / 1ps

module tb_fpga_aware_arithmetic;

    // -------------------------------------------------------------------------
    // Clock & Control
    // -------------------------------------------------------------------------
    reg clk;
    initial clk = 1'b0;
    always #5 clk = ~clk; // 100 MHz Simulation Clock

    integer total_tests  = 0;
    integer total_errors = 0;

    // -------------------------------------------------------------------------
    // DUT Signals
    // -------------------------------------------------------------------------
    // DUT 1: Booth Bit Cell
    reg  tb_a_curr, tb_a_prev;
    reg  tb_b_prev, tb_b_curr, tb_b_next;
    wire tb_pp_bit, tb_neg_flag;

    booth_bit_lut6_2 dut_booth_cell (
        .a_curr  (tb_a_curr),
        .a_prev  (tb_a_prev),
        .b_prev  (tb_b_prev),
        .b_curr  (tb_b_curr),
        .b_next  (tb_b_next),
        .pp_bit  (tb_pp_bit),
        .neg_flag(tb_neg_flag)
    );

    // DUT 2: 8-Bit FPGA Adder
    reg  [7:0] tb_add8_a, tb_add8_b;
    reg        tb_add8_cin;
    wire [7:0] tb_add8_sum;
    wire       tb_add8_cout;

    fpga_aware_adder8 dut_adder8 (
        .a(tb_add8_a), .b(tb_add8_b), .cin(tb_add8_cin),
        .sum(tb_add8_sum), .cout(tb_add8_cout)
    );

    // DUT 3: 10-Bit FPGA Adder
    reg  [9:0] tb_add10_a, tb_add10_b;
    reg        tb_add10_cin;
    wire [9:0] tb_add10_sum;
    wire       tb_add10_cout;

    fpga_aware_adder_10bit dut_adder10 (
        .a(tb_add10_a), .b(tb_add10_b), .cin(tb_add10_cin),
        .sum(tb_add10_sum), .cout(tb_add10_cout)
    );

    // DUT 4: 16-Bit FPGA Adder
    reg  [15:0] tb_add16_a, tb_add16_b;
    reg         tb_add16_cin;
    wire [15:0] tb_add16_sum;
    wire        tb_add16_cout;

    fpga_aware_adder16 dut_adder16 (
        .a(tb_add16_a), .b(tb_add16_b), .cin(tb_add16_cin),
        .sum(tb_add16_sum), .cout(tb_add16_cout)
    );

    // DUT 5: 8x8 FPGA Booth Multiplier
    reg  signed [7:0]  tb_mult_a, tb_mult_b;
    wire signed [15:0] tb_mult_prod;

    booth_multiplier_8x8_fpga_aware dut_multiplier (
        .a(tb_mult_a), .b(tb_mult_b), .prod(tb_mult_prod)
    );

    // =========================================================================
    // TASK 1: Test Booth Bit Cell (All 32 Combinations)
    // =========================================================================
    task automatic test_booth_cell();
        integer i, err;
        reg exp_pp, exp_neg;
        reg [2:0] grp;
        begin
            err = 0;
            $display("\n------------------------------------------------------------");
            $display("TEST 1: booth_bit_lut6_2 (All 32 Truth-Table Patterns)");
            $display("------------------------------------------------------------");

            for (i = 0; i < 32; i = i + 1) begin
                @(posedge clk);
                {tb_b_next, tb_b_curr, tb_b_prev, tb_a_prev, tb_a_curr} = i[4:0];
                #1;

                grp = {tb_b_next, tb_b_curr, tb_b_prev};
                case (grp)
                    3'b000: begin exp_pp = 1'b0;       exp_neg = 1'b0; end
                    3'b001: begin exp_pp = tb_a_curr;  exp_neg = 1'b0; end
                    3'b010: begin exp_pp = tb_a_curr;  exp_neg = 1'b0; end
                    3'b011: begin exp_pp = tb_a_prev;  exp_neg = 1'b0; end
                    3'b100: begin exp_pp = ~tb_a_prev; exp_neg = 1'b1; end
                    3'b101: begin exp_pp = ~tb_a_curr; exp_neg = 1'b1; end
                    3'b110: begin exp_pp = ~tb_a_curr; exp_neg = 1'b1; end
                    3'b111: begin exp_pp = 1'b0;       exp_neg = 1'b0; end
                endcase

                if (tb_pp_bit !== exp_pp || tb_neg_flag !== exp_neg) begin
                    $display("[ERROR Cell] Pattern %0d -> Actual={PP:%b, Neg:%b}, Expected={PP:%b, Neg:%b}",
                             i, tb_pp_bit, tb_neg_flag, exp_pp, exp_neg);
                    err = err + 1;
                end
                total_tests = total_tests + 1;
            end

            total_errors = total_errors + err;
            if (err == 0) $display(">>> TEST 1 PASSED: 32/32 Patterns Verified Bit-Accurate!");
            else          $display(">>> TEST 1 FAILED: %0d Errors!", err);
        end
    endtask

    // =========================================================================
    // TASK 2: Test 8-Bit FPGA Adder (Corners + 1,000 Random Vectors)
    // =========================================================================
    task automatic test_adder8();
        integer n, err, exp_val;
        reg [7:0] exp_s;
        reg       exp_co;
        begin
            err = 0;
            $display("\n------------------------------------------------------------");
            $display("TEST 2: fpga_aware_adder8 (Corners + 1,000 Random Vectors)");
            $display("------------------------------------------------------------");

            // Corner Tests
            for (n = 0; n < 1000; n = n + 1) begin
                @(posedge clk);
                if (n == 0)      begin tb_add8_a = 8'h00; tb_add8_b = 8'h00; tb_add8_cin = 1'b0; end
                else if (n == 1) begin tb_add8_a = 8'hFF; tb_add8_b = 8'h01; tb_add8_cin = 1'b0; end
                else if (n == 2) begin tb_add8_a = 8'hFF; tb_add8_b = 8'hFF; tb_add8_cin = 1'b1; end
                else if (n == 3) begin tb_add8_a = 8'hAA; tb_add8_b = 8'h55; tb_add8_cin = 1'b0; end
                else if (n == 4) begin tb_add8_a = 8'h7F; tb_add8_b = 8'h01; tb_add8_cin = 1'b0; end
                else begin
                    tb_add8_a   = $urandom_range(0, 255);
                    tb_add8_b   = $urandom_range(0, 255);
                    tb_add8_cin = $urandom_range(0, 1);
                end
                #1;

                exp_val = tb_add8_a + tb_add8_b + tb_add8_cin;
                exp_s   = exp_val[7:0];
                exp_co  = exp_val[8];

                if (tb_add8_sum !== exp_s || tb_add8_cout !== exp_co) begin
                    if (err < 5) begin
                        $display("[ERROR Add8] A=%0d B=%0d Cin=%0d | Act={S:%0d, Co:%b} Exp={S:%0d, Co:%b}",
                                 tb_add8_a, tb_add8_b, tb_add8_cin, tb_add8_sum, tb_add8_cout, exp_s, exp_co);
                    end
                    err = err + 1;
                end
                total_tests = total_tests + 1;
            end

            total_errors = total_errors + err;
            if (err == 0) $display(">>> TEST 2 PASSED: All 1,000 Vectors Verified Bit-Accurate!");
            else          $display(">>> TEST 2 FAILED: %0d Errors!", err);
        end
    endtask

    // =========================================================================
    // TASK 3: Test 10-Bit FPGA Adder (Corners + 1,000 Random Vectors)
    // =========================================================================
    task automatic test_adder10();
        integer n, err, exp_val;
        begin
            err = 0;
            $display("\n------------------------------------------------------------");
            $display("TEST 3: fpga_aware_adder_10bit (Corners + 1,000 Random Vectors)");
            $display("------------------------------------------------------------");

            for (n = 0; n < 1000; n = n + 1) begin
                @(posedge clk);
                if (n == 0)      begin tb_add10_a = 10'd0;    tb_add10_b = 10'd0;    tb_add10_cin = 1'b0; end
                else if (n == 1) begin tb_add10_a = 10'd1023; tb_add10_b = 10'd1;    tb_add10_cin = 1'b0; end
                else if (n == 2) begin tb_add10_a = 10'd1023; tb_add10_b = 10'd1023; tb_add10_cin = 1'b1; end
                else if (n == 3) begin tb_add10_a = 10'h2AA;  tb_add10_b = 10'h155;  tb_add10_cin = 1'b0; end
                else begin
                    tb_add10_a   = $urandom_range(0, 1023);
                    tb_add10_b   = $urandom_range(0, 1023);
                    tb_add10_cin = $urandom_range(0, 1);
                end
                #1;

                exp_val = tb_add10_a + tb_add10_b + tb_add10_cin;
                if (tb_add10_sum !== exp_val[9:0] || tb_add10_cout !== exp_val[10]) begin
                    if (err < 5) $display("[ERROR Add10] A=%0d B=%0d Cin=%0d", tb_add10_a, tb_add10_b, tb_add10_cin);
                    err = err + 1;
                end
                total_tests = total_tests + 1;
            end

            total_errors = total_errors + err;
            if (err == 0) $display(">>> TEST 3 PASSED: All 1,000 Vectors Verified Bit-Accurate!");
            else          $display(">>> TEST 3 FAILED: %0d Errors!", err);
        end
    endtask

    // =========================================================================
    // TASK 4: Test 16-Bit FPGA Adder (Corners + 1,000 Random Vectors)
    // =========================================================================
    task automatic test_adder16();
        integer n, err, exp_val;
        begin
            err = 0;
            $display("\n------------------------------------------------------------");
            $display("TEST 4: fpga_aware_adder16 (Corners + 1,000 Random Vectors)");
            $display("------------------------------------------------------------");

            for (n = 0; n < 1000; n = n + 1) begin
                @(posedge clk);
                if (n == 0)      begin tb_add16_a = 16'h0000; tb_add16_b = 16'h0000; tb_add16_cin = 1'b0; end
                else if (n == 1) begin tb_add16_a = 16'hFFFF; tb_add16_b = 16'h0001; tb_add16_cin = 1'b0; end
                else if (n == 2) begin tb_add16_a = 16'hFFFF; tb_add16_b = 16'hFFFF; tb_add16_cin = 1'b1; end
                else if (n == 3) begin tb_add16_a = 16'hAAAA; tb_add16_b = 16'h5555; tb_add16_cin = 1'b0; end
                else if (n == 4) begin tb_add16_a = 16'h7FFF; tb_add16_b = 16'h0001; tb_add16_cin = 1'b0; end
                else begin
                    tb_add16_a   = $urandom_range(0, 65535);
                    tb_add16_b   = $urandom_range(0, 65535);
                    tb_add16_cin = $urandom_range(0, 1);
                end
                #1;

                exp_val = tb_add16_a + tb_add16_b + tb_add16_cin;
                if (tb_add16_sum !== exp_val[15:0] || tb_add16_cout !== exp_val[16]) begin
                    if (err < 5) $display("[ERROR Add16] A=%0h B=%0h Cin=%0d", tb_add16_a, tb_add16_b, tb_add16_cin);
                    err = err + 1;
                end
                total_tests = total_tests + 1;
            end

            total_errors = total_errors + err;
            if (err == 0) $display(">>> TEST 4 PASSED: All 1,000 Vectors Verified Bit-Accurate!");
            else          $display(">>> TEST 4 FAILED: %0d Errors!", err);
        end
    endtask

    // =========================================================================
    // TASK 5: Test 8x8 FPGA Booth Multiplier (All Boundary Corners + 2,000 Randoms)
    // =========================================================================
    task automatic test_multiplier();
        integer n, err, exp_prod;
        reg signed [15:0] exp_p16;
        begin
            err = 0;
            $display("\n------------------------------------------------------------");
            $display("TEST 5: booth_multiplier_8x8_fpga_aware (Signed Corners + 2,000 Randoms)");
            $display("------------------------------------------------------------");

            for (n = 0; n < 2000; n = n + 1) begin
                @(posedge clk);
                // Critical boundary conditions
                if (n == 0)       begin tb_mult_a = 8'sd0;    tb_mult_b = 8'sd0;    end
                else if (n == 1)  begin tb_mult_a = 8'sd127;  tb_mult_b = 8'sd127;  end // (+127) * (+127) = +16129
                else if (n == 2)  begin tb_mult_a = -8'sd128; tb_mult_b = 8'sd127;  end // (-128) * (+127) = -16256
                else if (n == 3)  begin tb_mult_a = -8'sd128; tb_mult_b = -8'sd128; end // (-128) * (-128) = +16384
                else if (n == 4)  begin tb_mult_a = 8'sd1;    tb_mult_b = -8'sd1;   end // (+1) * (-1) = -1
                else if (n == 5)  begin tb_mult_a = -8'sd1;   tb_mult_b = -8'sd1;   end // (-1) * (-1) = +1
                else if (n == 6)  begin tb_mult_a = 8'sd64;   tb_mult_b = -8'sd64;  end
                else if (n == 7)  begin tb_mult_a = 8'sd0;    tb_mult_b = -8'sd128; end
                else begin
                    tb_mult_a = $urandom_range(0, 255) - 128;
                    tb_mult_b = $urandom_range(0, 255) - 128;
                end
                #1;

                exp_prod = int'(tb_mult_a) * int'(tb_mult_b);
                exp_p16  = exp_prod[15:0];

                if (tb_mult_prod !== exp_p16) begin
                    if (err < 5) begin
                        $display("[ERROR Mult] A=%4d B=%4d | Act Prod=%6d (%h) | Exp Prod=%6d (%h)",
                                 tb_mult_a, tb_mult_b, tb_mult_prod, tb_mult_prod, exp_p16, exp_p16);
                    end
                    err = err + 1;
                end
                total_tests = total_tests + 1;
            end

            total_errors = total_errors + err;
            if (err == 0) $display(">>> TEST 5 PASSED: All 2,000 Multiplications Verified Bit-Accurate!");
            else          $display(">>> TEST 5 FAILED: %0d Errors!", err);
        end
    endtask

    // =========================================================================
    // MAIN EXECUTION
    // =========================================================================
    initial begin
        $display("================================================================");
        $display("   STARTING FPGA FABRIC-AWARE ARITHMETIC VERIFICATION SUITE     ");
        $display("================================================================");

        // Reset inputs
        tb_a_curr = 0; tb_a_prev = 0; tb_b_prev = 0; tb_b_curr = 0; tb_b_next = 0;
        tb_add8_a = 0; tb_add8_b = 0; tb_add8_cin = 0;
        tb_add10_a = 0; tb_add10_b = 0; tb_add10_cin = 0;
        tb_add16_a = 0; tb_add16_b = 0; tb_add16_cin = 0;
        tb_mult_a = 0; tb_mult_b = 0;

        repeat (2) @(posedge clk);

        test_booth_cell();
        test_adder8();
        test_adder10();
        test_adder16();
        test_multiplier();

        $display("\n================================================================");
        if (total_errors == 0) begin
            $display("VERIFICATION SUMMARY: ALL %0d TESTS PASSED WITH 0 ERRORS!", total_tests);
            $display("STATUS: FPGA FABRIC-AWARE ADDERS & MULTIPLIERS 100%% VERIFIED");
        end else begin
            $display("VERIFICATION SUMMARY: FAILED WITH %0d ERRORS OUT OF %0d TESTS.", total_errors, total_tests);
        end
        $display("================================================================\n");
        $finish;
    end

endmodule