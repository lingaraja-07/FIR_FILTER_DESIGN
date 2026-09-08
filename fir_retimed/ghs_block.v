// Generate Half Sum (GHS) Block
// Computes half-sum S0 = A ^ B and half-carry C0 = A & B
`timescale 1ns / 1ps

module ghs_block #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] s0,
    output wire [WIDTH-1:0] c0
);
    assign s0 = a ^ b;
    assign c0 = a & b;
endmodule