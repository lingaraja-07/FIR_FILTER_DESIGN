// Top-Level 32-Tap Retimed FIR Filter Architecture
// Combines 1x 4-tap SF, 1x 4-tap DSF, and 3x 8-tap DSFs
// Employs dR1, dR2, dR3, dR4 retiming registers and 16-bit SRCSLAs
`timescale 1ns / 1ps

module retimed_fir_filter_32tap (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     valid_in,
    input  wire signed [7:0]        x_in,
    input  wire                     coeff_reload,
    input  wire signed [255:0]      coeff_in,
    output reg                      valid_out,
    output reg  signed [15:0]       y_out
);
    // Internal Coefficient Registers
    
    reg signed [7:0] h [0:31];
    integer k;

    // Default ECG Bandpass / Lowpass Denoising Filter Coefficients (Symmetric)
    // Default 360 Hz ECG Lowpass Filter (fc = 40 Hz, 32 Taps)
    initial begin
        h[0]  = -8'sd1;  h[1]  = -8'sd1;  h[2]  = -8'sd1;  h[3]  =  8'sd0;
        h[4]  =  8'sd0;  h[5]  =  8'sd1;  h[6]  =  8'sd2;  h[7]  =  8'sd4;
        h[8]  =  8'sd5;  h[9]  =  8'sd6;  h[10] =  8'sd8;  h[11] =  8'sd10;
        h[12] =  8'sd11; h[13] =  8'sd12; h[14] =  8'sd12; h[15] =  8'sd12;
        h[16] =  8'sd12; h[17] =  8'sd12; h[18] =  8'sd11; h[19] =  8'sd10;
        h[20] =  8'sd8;  h[21] =  8'sd6;  h[22] =  8'sd5;  h[23] =  8'sd4;
        h[24] =  8'sd2;  h[25] =  8'sd1;  h[26] =  8'sd0;  h[27] =  8'sd0;
        h[28] = -8'sd1;  h[29] = -8'sd1;  h[30] = -8'sd1;  h[31] = -8'sd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Re-load defaults on reset
        h[0]  = -8'sd1;  h[1]  = -8'sd1;  h[2]  = -8'sd1;  h[3]  =  8'sd0;
        h[4]  =  8'sd0;  h[5]  =  8'sd1;  h[6]  =  8'sd2;  h[7]  =  8'sd4;
        h[8]  =  8'sd5;  h[9]  =  8'sd6;  h[10] =  8'sd8;  h[11] =  8'sd10;
        h[12] =  8'sd11; h[13] =  8'sd12; h[14] =  8'sd12; h[15] =  8'sd12;
        h[16] =  8'sd12; h[17] =  8'sd12; h[18] =  8'sd11; h[19] =  8'sd10;
        h[20] =  8'sd8;  h[21] =  8'sd6;  h[22] =  8'sd5;  h[23] =  8'sd4;
        h[24] =  8'sd2;  h[25] =  8'sd1;  h[26] =  8'sd0;  h[27] =  8'sd0;
        h[28] = -8'sd1;  h[29] = -8'sd1;  h[30] = -8'sd1;  h[31] = -8'sd1;
        end else if (coeff_reload) begin
            for (k = 0; k < 32; k = k + 1) begin
                h[k] <= coeff_in[k*8 +: 8];
            end
        end
    end

    // Tap Input Delay Line (x[0] = x(n), x[1] = x(n-1), ..., x[31] = x(n-31))
    reg signed [7:0] x_pipe [0:31];
    integer tap_idx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (tap_idx = 0; tap_idx < 32; tap_idx = tap_idx + 1)
                x_pipe[tap_idx] <= 8'sd0;
        end else if (valid_in) begin
            x_pipe[0] <= x_in;
            for (tap_idx = 1; tap_idx < 32; tap_idx = tap_idx + 1)
                x_pipe[tap_idx] <= x_pipe[tap_idx-1];
        end
    end

    // Valid Strobe Pipeline (5 Pipeline Cycles Latency)
    reg [4:0] v_pipe;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v_pipe <= 5'b0;
        end else begin
            v_pipe <= {v_pipe[3:0], valid_in};
        end
    end

    // Sub-Filter Instantiations
    // Sub-filter 0: 4-tap SF (Taps 0..3)
    wire signed [15:0] sf0_sum;
    fir_subfilter_4tap u_sf0 (
        .clk(clk), .rst_n(rst_n), .enable(valid_in),
        .x0(x_pipe[0]), .x1(x_pipe[1]), .x2(x_pipe[2]), .x3(x_pipe[3]),
        .h0(h[0]),      .h1(h[1]),      .h2(h[2]),      .h3(h[3]),
        .sum_out(sf0_sum)
    );

    // Sub-filter 1: 4-tap DSF1 (Taps 4..7)
    wire signed [15:0] dsf1_sum;
    fir_subfilter_4tap u_dsf1 (
        .clk(clk), .rst_n(rst_n), .enable(valid_in),
        .x0(x_pipe[4]), .x1(x_pipe[5]), .x2(x_pipe[6]), .x3(x_pipe[7]),
        .h0(h[4]),      .h1(h[5]),      .h2(h[6]),      .h3(h[7]),
        .sum_out(dsf1_sum)
    );

    // Sub-filter 2: 8-tap DSF2 (Taps 8..15)
    wire signed [15:0] dsf2_sum;
    fir_subfilter_8tap u_dsf2 (
        .clk(clk), .rst_n(rst_n), .enable(valid_in),
        .x0(x_pipe[8]),  .x1(x_pipe[9]),  .x2(x_pipe[10]), .x3(x_pipe[11]),
        .x4(x_pipe[12]), .x5(x_pipe[13]), .x6(x_pipe[14]), .x7(x_pipe[15]),
        .h0(h[8]),       .h1(h[9]),       .h2(h[10]),      .h3(h[11]),
        .h4(h[12]),      .h5(h[13]),      .h6(h[14]),      .h7(h[15]),
        .sum_out(dsf2_sum)
    );

    // Sub-filter 3: 8-tap DSF3 (Taps 16..23)
    wire signed [15:0] dsf3_sum;
    fir_subfilter_8tap u_dsf3 (
        .clk(clk), .rst_n(rst_n), .enable(valid_in),
        .x0(x_pipe[16]), .x1(x_pipe[17]), .x2(x_pipe[18]), .x3(x_pipe[19]),
        .x4(x_pipe[20]), .x5(x_pipe[21]), .x6(x_pipe[22]), .x7(x_pipe[23]),
        .h0(h[16]),      .h1(h[17]),      .h2(h[18]),      .h3(h[19]),
        .h4(h[20]),      .h5(h[21]),      .h6(h[22]),      .h7(h[23]),
        .sum_out(dsf3_sum)
    );

    // Sub-filter 4: 8-tap DSF4 (Taps 24..31)
    wire signed [15:0] dsf4_sum;
    fir_subfilter_8tap u_dsf4 (
        .clk(clk), .rst_n(rst_n), .enable(valid_in),
        .x0(x_pipe[24]), .x1(x_pipe[25]), .x2(x_pipe[26]), .x3(x_pipe[27]),
        .x4(x_pipe[28]), .x5(x_pipe[29]), .x6(x_pipe[30]), .x7(x_pipe[31]),
        .h0(h[24]),      .h1(h[25]),      .h2(h[26]),      .h3(h[27]),
        .h4(h[28]),      .h5(h[29]),      .h6(h[30]),      .h7(h[31]),
        .sum_out(dsf4_sum)
    );

    // Retiming Stage dR3 Registers (Captures DSF sub-filter sums)
    reg signed [15:0] reg_dr3_dsf1, reg_dr3_dsf2, reg_dr3_dsf3, reg_dr3_dsf4;
    reg signed [15:0] reg_dr3_sf0_delay1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_dr3_dsf1       <= 16'sd0;
            reg_dr3_dsf2       <= 16'sd0;
            reg_dr3_dsf3       <= 16'sd0;
            reg_dr3_dsf4       <= 16'sd0;
            reg_dr3_sf0_delay1 <= 16'sd0;
        end else if (valid_in) begin
            reg_dr3_dsf1       <= dsf1_sum;
            reg_dr3_dsf2       <= dsf2_sum;
            reg_dr3_dsf3       <= dsf3_sum;
            reg_dr3_dsf4       <= dsf4_sum;
            reg_dr3_sf0_delay1 <= sf0_sum;
        end
    end

    // Combinational Adders between dR3 and dR2
    wire [15:0] sum_dsf12_comb, sum_dsf34_comb;
    wire        co_dsf12, co_dsf34;

    srcsla_16bit u_add_dsf12 (
        .a(reg_dr3_dsf1), .b(reg_dr3_dsf2), .cin(1'b0), .sum(sum_dsf12_comb), .cout(co_dsf12)
    );

    srcsla_16bit u_add_dsf34 (
        .a(reg_dr3_dsf3), .b(reg_dr3_dsf4), .cin(1'b0), .sum(sum_dsf34_comb), .cout(co_dsf34)
    );

    // Retiming Stage dR2 Registers
    reg signed [15:0] reg_dr2_dsf12, reg_dr2_dsf34;
    reg signed [15:0] reg_dr2_sf0_delay2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_dr2_dsf12      <= 16'sd0;
            reg_dr2_dsf34      <= 16'sd0;
            reg_dr2_sf0_delay2 <= 16'sd0;
        end else if (valid_in) begin
            reg_dr2_dsf12      <= sum_dsf12_comb;
            reg_dr2_dsf34      <= sum_dsf34_comb;
            reg_dr2_sf0_delay2 <= reg_dr3_sf0_delay1;
        end
    end

    // Combinational Adder between dR2 and dR1
    wire [15:0] sum_dsf_all_comb;
    wire        co_dsf_all;

    srcsla_16bit u_add_dsf_all (
        .a(reg_dr2_dsf12), .b(reg_dr2_dsf34), .cin(1'b0), .sum(sum_dsf_all_comb), .cout(co_dsf_all)
    );

    // Retiming Stage dR1 Registers
    reg signed [15:0] reg_dr1_dsf_all;
    reg signed [15:0] reg_dr1_sf0_delay3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_dr1_dsf_all    <= 16'sd0;
            reg_dr1_sf0_delay3 <= 16'sd0;
        end else if (valid_in) begin
            reg_dr1_dsf_all    <= sum_dsf_all_comb;
            reg_dr1_sf0_delay3 <= reg_dr2_sf0_delay2;
        end
    end

    // Final Output SRCSLA Addition (SF0 + All DSFs)
    wire [15:0] final_filter_sum;
    wire        final_filter_cout;

    srcsla_16bit u_add_final_stage (
        .a(reg_dr1_sf0_delay3), .b(reg_dr1_dsf_all), .cin(1'b0), .sum(final_filter_sum), .cout(final_filter_cout)
    );

    // Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            y_out     <= 16'sd0;
        end else begin
            valid_out <= v_pipe[4];
            y_out     <= final_filter_sum;
        end
    end
endmodule