// Carry Generation for Cin = 1 (CG1) Block
// C1_1(0) = S0(0) | C0(0)
// C1_1(i) = C1_1(i-1) & S0(i) | C0(i)
`timescale 1ns / 1ps

module cg1_block #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] s0,
    input  wire [WIDTH-1:0] c0,
    output wire [WIDTH-1:0] c1_1
);
    wire [WIDTH-1:0] c_chain;

    assign c_chain[0] = s0[0] | c0[0];

    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_cg1
            assign c_chain[i] = (c_chain[i-1] & s0[i]) | c0[i];
        end
    endgenerate

    assign c1_1 = c_chain;
endmodule