// 4-Tap Retimed Sub-Filter
// Contains 4 RBMs, dR4 pipeline registers, and a 16-bit SRCSLA Adder Tree
`timescale 1ns / 1ps

module fir_subfilter_4tap (
    input  wire               clk,
    input  wire               rst_n,
    input  wire               enable,
    input  wire signed [7:0]  x0, x1, x2, x3,
    input  wire signed [7:0]  h0, h1, h2, h3,
    output reg  signed [15:0] sum_out
);
    // Multiplier Combinational Outputs
    wire signed [15:0] p0_comb, p1_comb, p2_comb, p3_comb;

    radix4_booth_multiplier_8x8 u_m0 (.a(x0), .b(h0), .prod(p0_comb));
    radix4_booth_multiplier_8x8 u_m1 (.a(x1), .b(h1), .prod(p1_comb));
    radix4_booth_multiplier_8x8 u_m2 (.a(x2), .b(h2), .prod(p2_comb));
    radix4_booth_multiplier_8x8 u_m3 (.a(x3), .b(h3), .prod(p3_comb));

    // dR4 Retiming Pipeline Registers
    reg signed [15:0] p0_reg, p1_reg, p2_reg, p3_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p0_reg <= 16'sd0;
            p1_reg <= 16'sd0;
            p2_reg <= 16'sd0;
            p3_reg <= 16'sd0;
        end else if (enable) begin
            p0_reg <= p0_comb;
            p1_reg <= p1_comb;
            p2_reg <= p2_comb;
            p3_reg <= p3_comb;
        end
    end

    // Tree Stage 1: Add (P0+P1) and (P2+P3)
    wire [15:0] sum_01, sum_23;
    wire        co_01, co_23;

    srcsla_16bit u_add01 (
        .a(p0_reg), .b(p1_reg), .cin(1'b0), .sum(sum_01), .cout(co_01)
    );

    srcsla_16bit u_add23 (
        .a(p2_reg), .b(p3_reg), .cin(1'b0), .sum(sum_23), .cout(co_23)
    );

    // Tree Stage 2: Final 4-tap sum
    wire [15:0] tree_sum;
    wire        tree_cout;

    srcsla_16bit u_add_tree (
        .a(sum_01), .b(sum_23), .cin(1'b0), .sum(tree_sum), .cout(tree_cout)
    );

    always @(*) begin
        sum_out = tree_sum;
    end
endmodule