// 16-bit SRCSLA: 2-bit RCA + 2-bit CSLA + 3-bit CSLA + 4-bit CSLA + 5-bit CSLA
`timescale 1ns / 1ps

module srcsla_16bit (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire        cin,
    output wire [15:0] sum,
    output wire        cout
);
    wire c1, c2, c3, c4;

    rca_slice #(.WIDTH(2)) stg0 (
        .a(a[1:0]), .b(b[1:0]), .cin(cin), .sum(sum[1:0]), .cout(c1)
    );

    csla_slice #(.WIDTH(2)) stg1 (
        .a(a[3:2]), .b(b[3:2]), .cin(c1), .sum(sum[3:2]), .cout(c2)
    );

    csla_slice #(.WIDTH(3)) stg2 (
        .a(a[6:4]), .b(b[6:4]), .cin(c2), .sum(sum[6:4]), .cout(c3)
    );

    csla_slice #(.WIDTH(4)) stg3 (
        .a(a[10:7]), .b(b[10:7]), .cin(c3), .sum(sum[10:7]), .cout(c4)
    );

    csla_slice #(.WIDTH(5)) stg4 (
        .a(a[15:11]), .b(b[15:11]), .cin(c4), .sum(sum[15:11]), .cout(cout)
    );
endmodule