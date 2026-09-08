// 10-bit SRCSLA: 3-bit RCA + 3-bit CSLA + 4-bit CSLA
`timescale 1ns / 1ps

module srcsla_10bit (
    input  wire [9:0] a,
    input  wire [9:0] b,
    input  wire       cin,
    output wire [9:0] sum,
    output wire       cout
);
    wire c1, c2;

    rca_slice #(.WIDTH(3)) stg0 (
        .a(a[2:0]), .b(b[2:0]), .cin(cin), .sum(sum[2:0]), .cout(c1)
    );

    csla_slice #(.WIDTH(3)) stg1 (
        .a(a[5:3]), .b(b[5:3]), .cin(c1), .sum(sum[5:3]), .cout(c2)
    );

    csla_slice #(.WIDTH(4)) stg2 (
        .a(a[9:6]), .b(b[9:6]), .cin(c2), .sum(sum[9:6]), .cout(cout)
    );
endmodule