// Carry Select (CS) Block
// Optimized AND-OR logic: C(i) = (Cin & C1_1(i)) | C1_0(i)
`timescale 1ns / 1ps

module cs_block #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] c1_0,
    input  wire [WIDTH-1:0] c1_1,
    input  wire             cin,
    output wire [WIDTH-1:0] c_out,
    output wire             cout
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_cs
            assign c_out[i] = (cin & c1_1[i]) | c1_0[i];
        end
    endgenerate

    assign cout = c_out[WIDTH-1];
endmodule