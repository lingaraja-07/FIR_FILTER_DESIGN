// Binary to 2's Complement Converter (B2CC)
// Computes 9-bit -A from 8-bit A in two's complement
`timescale 1ns / 1ps

module b2cc_8bit (
    input  wire [7:0] a,
    output wire [8:0] neg_a
);
    wire [7:0] c;

    assign neg_a[0] = a[0];
    assign c[0]     = a[0];

    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : gen_b2cc
            assign neg_a[i] = a[i] ^ c[i-1];
            assign c[i]     = a[i] | c[i-1];
        end
    endgenerate

    // 9th bit: Sign of negated value
    assign neg_a[8] = (a == 8'b1000_0000) ? 1'b0 :
                      (a == 8'b0000_0000) ? 1'b0 : ~a[7];
endmodule