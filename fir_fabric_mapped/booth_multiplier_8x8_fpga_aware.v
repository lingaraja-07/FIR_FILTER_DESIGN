// 8x8 Radix-4 Booth Multiplier mapped to FPGA Fabric
`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module booth_multiplier_8x8_fpga_aware (
    input  wire signed [7:0]  a,
    input  wire signed [7:0]  b,
    output wire signed [15:0] prod
);
    wire signed [9:0] pp0, pp1, pp2, pp3;

    // 4 Radix-4 Booth Groups
    booth_radix4_group u_grp0 (.a(a), .b_prev(1'b0), .b_curr(b[0]), .b_next(b[1]), .pp(pp0));
    booth_radix4_group u_grp1 (.a(a), .b_prev(b[1]), .b_curr(b[2]), .b_next(b[3]), .pp(pp1));
    booth_radix4_group u_grp2 (.a(a), .b_prev(b[3]), .b_curr(b[4]), .b_next(b[5]), .pp(pp2));
    booth_radix4_group u_grp3 (.a(a), .b_prev(b[5]), .b_curr(b[6]), .b_next(b[7]), .pp(pp3));

    // Sign-extended 16-bit partial product terms with bit shifts
    wire [15:0] term0 = {{6{pp0[9]}}, pp0};
    wire [15:0] term1 = {{4{pp1[9]}}, pp1, 2'b00};
    wire [15:0] term2 = {{2{pp2[9]}}, pp2, 4'b0000};
    wire [15:0] term3 = {pp3, 6'b000000};

    // FPGA-Aware Reduction Tree
    wire [15:0] sum01, sum23;
    wire        co01, co23, co_final;

    fpga_aware_adder16 u_add01 (
        .a(term0), .b(term1), .cin(1'b0), .sum(sum01), .cout(co01)
    );

    fpga_aware_adder16 u_add23 (
        .a(term2), .b(term3), .cin(1'b0), .sum(sum23), .cout(co23)
    );

    fpga_aware_adder16 u_add_final (
        .a(sum01), .b(sum23), .cin(1'b0), .sum(prod), .cout(co_final)
    );

endmodule