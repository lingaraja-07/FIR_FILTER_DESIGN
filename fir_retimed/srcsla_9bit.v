// 9-bit SRCSLA: 2-bit RCA + 3-bit CSLA + 4-bit CSLA
`timescale 1ns / 1ps

module srcsla_9bit (
    input  wire [8:0] a,
    input  wire [8:0] b,
    input  wire       cin,
    output wire [8:0] sum,
    output wire       cout
);
    wire c1, c2;

    rca_slice #(.WIDTH(2)) stg0 (
        .a(a[1:0]), .b(b[1:0]), .cin(cin), .sum(sum[1:0]), .cout(c1)
    );

    csla_slice #(.WIDTH(3)) stg1 (
        .a(a[4:2]), .b(b[4:2]), .cin(c1), .sum(sum[4:2]), .cout(c2)
    );

    csla_slice #(.WIDTH(4)) stg2 (
        .a(a[8:5]), .b(b[8:5]), .cin(c2), .sum(sum[8:5]), .cout(cout)
    );
endmodule