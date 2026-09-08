// 16-Bit FPGA Fabric-Aware Adder
`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module fpga_aware_adder16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        cin,
    output wire [15:0] sum,
    output wire        cout
);
    wire c_mid;

    fpga_aware_adder8 u_add_lo (
        .a(a[7:0]), .b(b[7:0]), .cin(cin), .sum(sum[7:0]), .cout(c_mid)
    );

    fpga_aware_adder8 u_add_hi (
        .a(a[15:8]), .b(b[15:8]), .cin(c_mid), .sum(sum[15:8]), .cout(cout)
    );
endmodule