// Parameterizable CSLA Unit combining GHS, CG0, CG1, CS, and GFS
`timescale 1ns / 1ps

module csla_slice #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire             cin,
    output wire [WIDTH-1:0] sum,
    output wire             cout
);
    wire [WIDTH-1:0] s0;
    wire [WIDTH-1:0] c0;
    wire [WIDTH-1:0] c1_0;
    wire [WIDTH-1:0] c1_1;
    wire [WIDTH-1:0] c_sel;

    ghs_block #(.WIDTH(WIDTH)) u_ghs (
        .a(a), .b(b), .s0(s0), .c0(c0)
    );

    cg0_block #(.WIDTH(WIDTH)) u_cg0 (
        .s0(s0), .c0(c0), .c1_0(c1_0)
    );

    cg1_block #(.WIDTH(WIDTH)) u_cg1 (
        .s0(s0), .c0(c0), .c1_1(c1_1)
    );

    cs_block #(.WIDTH(WIDTH)) u_cs (
        .c1_0(c1_0), .c1_1(c1_1), .cin(cin), .c_out(c_sel), .cout(cout)
    );

    gfs_block #(.WIDTH(WIDTH)) u_gfs (
        .s0(s0), .c_sel(c_sel), .cin(cin), .sum(sum)
    );
endmodule