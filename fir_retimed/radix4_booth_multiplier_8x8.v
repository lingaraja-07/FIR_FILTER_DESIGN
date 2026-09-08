// 8x8 Radix-4 Booth Multiplier with SRCSLA Accumulation
// Computes 16-bit signed product P = A * B
`timescale 1ns / 1ps

module radix4_booth_multiplier_8x8 (
    input  wire signed [7:0]  a,
    input  wire signed [7:0]  b,
    output wire signed [15:0] prod
);
    // Stage 1: Multiplicand negation and partial product generation
    wire [8:0] neg_a;
    b2cc_8bit u_b2cc (
        .a(a),
        .neg_a(neg_a)
    );

    wire [9:0] pp0, pp1, pp2, pp3;

    // PP0: bits (b[1], b[0], 1'b0)
    booth_encoder_selector u_be0 (
        .b_curr_plus1(b[1]),
        .b_curr(b[0]),
        .b_prev(1'b0),
        .pos_a(a),
        .neg_a(neg_a),
        .pp(pp0)
    );

    // PP1: bits (b[3], b[2], b[1])
    booth_encoder_selector u_be1 (
        .b_curr_plus1(b[3]),
        .b_curr(b[2]),
        .b_prev(b[1]),
        .pos_a(a),
        .neg_a(neg_a),
        .pp(pp1)
    );

    // PP2: bits (b[5], b[4], b[3])
    booth_encoder_selector u_be2 (
        .b_curr_plus1(b[5]),
        .b_curr(b[4]),
        .b_prev(b[3]),
        .pos_a(a),
        .neg_a(neg_a),
        .pp(pp2)
    );

    // PP3: bits (b[7], b[6], b[5])
    booth_encoder_selector u_be3 (
        .b_curr_plus1(b[7]),
        .b_curr(b[6]),
        .b_prev(b[5]),
        .pos_a(a),
        .neg_a(neg_a),
        .pp(pp3)
    );

    // Product bit alignment:
    // P = PP0 + (PP1 << 2) + (PP2 << 4) + (PP3 << 6)
    // Stage 2: Pairwise SRCSLA additions
    wire [15:0] ext_pp0 = {{6{pp0[9]}}, pp0};
    wire [15:0] ext_pp1 = {{4{pp1[9]}}, pp1, 2'b00};
    wire [15:0] ext_pp2 = {{2{pp2[9]}}, pp2, 4'b0000};
    wire [15:0] ext_pp3 = {pp3, 6'b000000};

    // Group 01: Add PP0 and PP1<<2
    wire [9:0] sum_stg2_low;
    wire       cout_stg2_low;
    srcsla_10bit u_add_low (
        .a(ext_pp0[11:2]),
        .b(ext_pp1[11:2]),
        .cin(1'b0),
        .sum(sum_stg2_low),
        .cout(cout_stg2_low)
    );

    // Group 23: Add PP2 and PP3
    wire [8:0] sum_stg2_high;
    wire      cout_stg2_high;
    srcsla_9bit u_add_high (
        .a(ext_pp2[14:6]),
        .b(ext_pp3[14:6]),
        .cin(1'b0),
        .sum(sum_stg2_high),
        .cout(cout_stg2_high)
    );

    // Full 16-bit intermediate buses
    wire [15:0] stg2_sum_01 = {ext_pp0[15:12] + ext_pp1[15:12] + cout_stg2_low, sum_stg2_low, ext_pp0[1:0]};
    wire [15:0] stg2_sum_23 = {ext_pp2[15] + ext_pp3[15] + cout_stg2_high, sum_stg2_high, ext_pp2[5:0]};

    // Stage 3: Final 16-bit SRCSLA addition
    wire [15:0] final_product;
    wire        final_cout;
    srcsla_16bit u_add_final (
        .a(stg2_sum_01),
        .b(stg2_sum_23),
        .cin(1'b0),
        .sum(final_product),
        .cout(final_cout)
    );

    assign prod = final_product;
endmodule