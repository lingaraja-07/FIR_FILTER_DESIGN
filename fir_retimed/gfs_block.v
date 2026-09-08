// Generate Full Sum (GFS) Block
// S(0) = S0(0) ^ Cin
// S(i) = S0(i) ^ C(i-1)
`timescale 1ns / 1ps

module gfs_block #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] s0,
    input  wire [WIDTH-1:0] c_sel,
    input  wire             cin,
    output wire [WIDTH-1:0] sum
);
    assign sum[0] = s0[0] ^ cin;

    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_gfs
            assign sum[i] = s0[i] ^ c_sel[i-1];
        end
    endgenerate
endmodule