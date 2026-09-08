// Top-Level 32-Tap Retimed FIR Filter with Complete FPGA-Aware Architecture
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
    // Filter Coefficients (360 Hz ECG lowpass filter, fc = 40 Hz)
    reg signed [7:0] h [0:31];
    integer k;

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
            h[0]  <= -8'sd1;  h[1]  <= -8'sd1;  h[2]  <= -8'sd1;  h[3]  <=  8'sd0;
            h[4]  <=  8'sd0;  h[5]  <=  8'sd1;  h[6]  <=  8'sd2;  h[7]  <=  8'sd4;
            h[8]  <=  8'sd5;  h[9]  <=  8'sd6;  h[10] <=  8'sd8;  h[11] <=  8'sd10;
            h[12] <=  8'sd11; h[13] <=  8'sd12; h[14] <=  8'sd12; h[15] <=  8'sd12;
            h[16] <=  8'sd12; h[17] <=  8'sd12; h[18] <=  8'sd11; h[19] <=  8'sd10;
            h[20] <=  8'sd8;  h[21] <=  8'sd6;  h[22] <=  8'sd5;  h[23] <=  8'sd4;
            h[24] <=  8'sd2;  h[25] <=  8'sd1;  h[26] <=  8'sd0;  h[27] <=  8'sd0;
            h[28] <= -8'sd1;  h[29] <= -8'sd1;  h[30] <= -8'sd1;  h[31] <= -8'sd1;
        end else if (coeff_reload) begin
            for (k = 0; k < 32; k = k + 1) h[k] <= coeff_in[k*8 +: 8];
        end
    end

    // Tap Input Delay Line
    reg signed [7:0] x_pipe [0:31];
    integer tap_idx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (tap_idx = 0; tap_idx < 32; tap_idx = tap_idx + 1) x_pipe[tap_idx] <= 8'sd0;
        end else if (valid_in) begin
            x_pipe[0] <= x_in;
            for (tap_idx = 1; tap_idx < 32; tap_idx = tap_idx + 1) x_pipe[tap_idx] <= x_pipe[tap_idx-1];
        end
    end

    // 5-Cycle Latency Control Pipeline
    reg [4:0] v_pipe;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) v_pipe <= 5'b0;
        else        v_pipe <= {v_pipe[3:0], valid_in};
    end

    // Sub-Filter Instantiations
    wire signed [15:0] sf0_sum, dsf1_sum, dsf2_sum, dsf3_sum, dsf4_sum;

    fir_subfilter_4tap u_sf0 (
        .clk(clk), .rst_n(rst_n), .enable(valid_in),
        .x0(x_pipe[0]), .x1(x_pipe[1]), .x2(x_pipe[2]), .x3(x_pipe[3]),
        .h0(h[0]), .h1(h[1]), .h2(h[2]), .h3(h[3]), .sum_out(sf0_sum)
    );

    fir_subfilter_4tap u_dsf1 (
        .clk(clk), .rst_n(rst_n), .enable(valid_in),
        .x0(x_pipe[4]), .x1(x_pipe[5]), .x2(x_pipe[6]), .x3(x_pipe[7]),
        .h0(h[4]), .h1(h[5]), .h2(h[6]), .h3(h[7]), .sum_out(dsf1_sum)
    );

    fir_subfilter_8tap u_dsf2 (
        .clk(clk), .rst_n(rst_n), .enable(valid_in),
        .x0(x_pipe[8]),  .x1(x_pipe[9]),  .x2(x_pipe[10]), .x3(x_pipe[11]),
        .x4(x_pipe[12]), .x5(x_pipe[13]), .x6(x_pipe[14]), .x7(x_pipe[15]),
        .h0(h[8]), .h1(h[9]), .h2(h[10]), .h3(h[11]), .h4(h[12]), .h5(h[13]), .h6(h[14]), .h7(h[15]),
        .sum_out(dsf2_sum)
    );

    fir_subfilter_8tap u_dsf3 (
        .clk(clk), .rst_n(rst_n), .enable(valid_in),
        .x0(x_pipe[16]), .x1(x_pipe[17]), .x2(x_pipe[18]), .x3(x_pipe[19]),
        .x4(x_pipe[20]), .x5(x_pipe[21]), .x6(x_pipe[22]), .x7(x_pipe[23]),
        .h0(h[16]), .h1(h[17]), .h2(h[18]), .h3(h[19]), .h4(h[20]), .h5(h[21]), .h6(h[22]), .h7(h[23]),
        .sum_out(dsf3_sum)
    );

    fir_subfilter_8tap u_dsf4 (
        .clk(clk), .rst_n(rst_n), .enable(valid_in),
        .x0(x_pipe[24]), .x1(x_pipe[25]), .x2(x_pipe[26]), .x3(x_pipe[27]),
        .x4(x_pipe[28]), .x5(x_pipe[29]), .x6(x_pipe[30]), .x7(x_pipe[31]),
        .h0(h[24]), .h1(h[25]), .h2(h[26]), .h3(h[27]), .h4(h[28]), .h5(h[29]), .h6(h[30]), .h7(h[31]),
        .sum_out(dsf4_sum)
    );

    // Retiming Stage dR3
    reg signed [15:0] reg_dr3_dsf1, reg_dr3_dsf2, reg_dr3_dsf3, reg_dr3_dsf4, reg_dr3_sf0_d1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_dr3_dsf1 <= 16'sd0; reg_dr3_dsf2 <= 16'sd0;
            reg_dr3_dsf3 <= 16'sd0; reg_dr3_dsf4 <= 16'sd0;
            reg_dr3_sf0_d1 <= 16'sd0;
        end else if (valid_in) begin
            reg_dr3_dsf1 <= dsf1_sum; reg_dr3_dsf2 <= dsf2_sum;
            reg_dr3_dsf3 <= dsf3_sum; reg_dr3_dsf4 <= dsf4_sum;
            reg_dr3_sf0_d1 <= sf0_sum;
        end
    end

    // Inter-Stage FPGA-Aware Adders (dR3 to dR2)
    wire [15:0] sum_dsf12_comb, sum_dsf34_comb;
    wire        co12, co34;
    fpga_aware_adder16 u_add_dsf12 (.a(reg_dr3_dsf1), .b(reg_dr3_dsf2), .cin(1'b0), .sum(sum_dsf12_comb), .cout(co12));
    fpga_aware_adder16 u_add_dsf34 (.a(reg_dr3_dsf3), .b(reg_dr3_dsf4), .cin(1'b0), .sum(sum_dsf34_comb), .cout(co34));

    // Retiming Stage dR2
    reg signed [15:0] reg_dr2_dsf12, reg_dr2_dsf34, reg_dr2_sf0_d2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_dr2_dsf12 <= 16'sd0; reg_dr2_dsf34 <= 16'sd0; reg_dr2_sf0_d2 <= 16'sd0;
        end else if (valid_in) begin
            reg_dr2_dsf12 <= sum_dsf12_comb; reg_dr2_dsf34 <= sum_dsf34_comb;
            reg_dr2_sf0_d2 <= reg_dr3_sf0_d1;
        end
    end

    // Inter-Stage FPGA-Aware Adder (dR2 to dR1)
    wire [15:0] sum_dsf_all_comb;
    wire        co_all;
    fpga_aware_adder16 u_add_dsf_all (.a(reg_dr2_dsf12), .b(reg_dr2_dsf34), .cin(1'b0), .sum(sum_dsf_all_comb), .cout(co_all));

    // Retiming Stage dR1
    reg signed [15:0] reg_dr1_dsf_all, reg_dr1_sf0_d3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_dr1_dsf_all <= 16'sd0; reg_dr1_sf0_d3 <= 16'sd0;
        end else if (valid_in) begin
            reg_dr1_dsf_all <= sum_dsf_all_comb;
            reg_dr1_sf0_d3  <= reg_dr2_sf0_d2;
        end
    end

    // Final Output FPGA-Aware Adder (SF0 + All DSFs)
    wire [15:0] final_filter_sum;
    wire        co_final;
    fpga_aware_adder16 u_add_final_stage (.a(reg_dr1_sf0_d3), .b(reg_dr1_dsf_all), .cin(1'b0), .sum(final_filter_sum), .cout(co_final));

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