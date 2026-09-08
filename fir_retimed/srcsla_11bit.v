// 11-bit SRCSLA: 3-bit RCA + 4-bit CSLA + 4-bit CSLA
`timescale 1ns / 1ps

module srcsla_11bit (
    input  wire [10:0] a,
    input  wire [10:0] b,
    input  wire        cin,
    output wire [10:0] sum,
    output wire        cout
);
    wire c1, c2;

    rca_slice #(.WIDTH(3)) stg0 (
        .a(a[2:0]), .b(b[2:0]), .cin(cin), .sum(sum[2:0]), .cout(c1)
    );

    csla_slice #(.WIDTH(4)) stg1 (
        .a(a[6:3]), .b(b[6:3]), .cin(c1), .sum(sum[6:3]), .cout(c2)
    );

    csla_slice #(.WIDTH(4)) stg2 (
        .a(a[10:7]), .b(b[10:7]), .cin(c2), .sum(sum[10:7]), .cout(cout)
    );
endmodule