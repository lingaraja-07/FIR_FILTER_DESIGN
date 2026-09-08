// 8-Tap Retimed Sub-Filter
// Contains 8 RBMs, dR4 pipeline registers, and a 3-level 16-bit SRCSLA Adder Tree
`timescale 1ns / 1ps

module fir_subfilter_8tap (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               enable,
    input  wire signed [7:0]  x0, x1, x2, x3, x4, x5, x6, x7,
    input  wire signed [7:0]  h0, h1, h2, h3, h4, h5, h6, h7,
    output reg  signed [15:0] sum_out
);
    // Multiplier Combinational Outputs
    wire signed [15:0] p_comb [0:7];

    radix4_booth_multiplier_8x8 u_m0 (.a(x0), .b(h0), .prod(p_comb[0]));
    radix4_booth_multiplier_8x8 u_m1 (.a(x1), .b(h1), .prod(p_comb[1]));
    radix4_booth_multiplier_8x8 u_m2 (.a(x2), .b(h2), .prod(p_comb[2]));
    radix4_booth_multiplier_8x8 u_m3 (.a(x3), .b(h3), .prod(p_comb[3]));
    radix4_booth_multiplier_8x8 u_m4 (.a(x4), .b(h4), .prod(p_comb[4]));
    radix4_booth_multiplier_8x8 u_m5 (.a(x5), .b(h5), .prod(p_comb[5]));
    radix4_booth_multiplier_8x8 u_m6 (.a(x6), .b(h6), .prod(p_comb[6]));
    radix4_booth_multiplier_8x8 u_m7 (.a(x7), .b(h7), .prod(p_comb[7]));

    // dR4 Retiming Registers
    reg signed [15:0] p_reg [0:7];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1)
                p_reg[i] <= 16'sd0;
        end else if (enable) begin
            for (i = 0; i < 8; i = i + 1)
                p_reg[i] <= p_comb[i];
        end
    end

    // Tree Stage 1: 4 Adders
    wire [15:0] s1_01, s1_23, s1_45, s1_67;
    wire        co1_01, co1_23, co1_45, co1_67;

    srcsla_16bit u_add01 (.a(p_reg[0]), .b(p_reg[1]), .cin(1'b0), .sum(s1_01), .cout(co1_01));
    srcsla_16bit u_add23 (.a(p_reg[2]), .b(p_reg[3]), .cin(1'b0), .sum(s1_23), .cout(co1_23));
    srcsla_16bit u_add45 (.a(p_reg[4]), .b(p_reg[5]), .cin(1'b0), .sum(s1_45), .cout(co1_45));
    srcsla_16bit u_add67 (.a(p_reg[6]), .b(p_reg[7]), .cin(1'b0), .sum(s1_67), .cout(co1_67));

    // Tree Stage 2: 2 Adders
    wire [15:0] s2_03, s2_47;
    wire        co2_03, co2_47;

    srcsla_16bit u_add03 (.a(s1_01), .b(s1_23), .cin(1'b0), .sum(s2_03), .cout(co2_03));
    srcsla_16bit u_add47 (.a(s1_45), .b(s1_67), .cin(1'b0), .sum(s2_47), .cout(co2_47));

    // Tree Stage 3: 1 Adder
    wire [15:0] s3_07;
    wire        co3_07;

    srcsla_16bit u_add07 (.a(s2_03), .b(s2_47), .cin(1'b0), .sum(s3_07), .cout(co3_07));

    always @(*) begin
        sum_out = s3_07;
    end
endmodule