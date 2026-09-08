// Carry Generation for Cin = 0 (CG0) Block
// C1_0(0) = C0(0)
// C1_0(i) = C1_0(i-1) & S0(i) | C0(i)
`timescale 1ns / 1ps

module cg0_block #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] s0,
    input  wire [WIDTH-1:0] c0,
    output wire [WIDTH-1:0] c1_0
);
    wire [WIDTH-1:0] c_chain;

    assign c_chain[0] = c0[0];

    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_cg0
            assign c_chain[i] = (c_chain[i-1] & s0[i]) | c0[i];
        end
    endgenerate

    assign c1_0 = c_chain;
endmodule