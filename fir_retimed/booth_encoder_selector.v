// Radix-4 Booth Encoder and Selector
// Generates 10-bit sign-extended Partial Product (PPi)
`timescale 1ns / 1ps

module booth_encoder_selector (
    input  wire       b_curr_plus1, // B(2i+1)
    input  wire       b_curr,       // B(2i)
    input  wire       b_prev,       // B(2i-1)
    input  wire [7:0] pos_a,        // +A
    input  wire [8:0] neg_a,        // -A
    output reg  [9:0] pp            // 10-bit partial product
);
    wire sel_zero, sel_pos_a, sel_pos_2a, sel_neg_2a, sel_neg_a;
    wire [2:0] code = {b_curr_plus1, b_curr, b_prev};

    // Radix-4 Booth Truth Table:
    // 000 -> 0
    // 001 -> +1 * A
    // 010 -> +1 * A
    // 011 -> +2 * A
    // 100 -> -2 * A
    // 101 -> -1 * A
    // 110 -> -1 * A
    // 111 -> 0
    assign sel_zero   = (code == 3'b000) || (code == 3'b111);
    assign sel_pos_a  = (code == 3'b001) || (code == 3'b010);
    assign sel_pos_2a = (code == 3'b011);
    assign sel_neg_2a = (code == 3'b100);
    assign sel_neg_a  = (code == 3'b101) || (code == 3'b110);

    wire [9:0] val_pos_a  = {{2{pos_a[7]}}, pos_a};
    wire [9:0] val_pos_2a = {{1{pos_a[7]}}, pos_a, 1'b0};
    wire [9:0] val_neg_a  = {{1{neg_a[8]}}, neg_a};
    wire [9:0] val_neg_2a = {neg_a[8:0], 1'b0};

    always @(*) begin
        if (sel_zero)
            pp = 10'd0;
        else if (sel_pos_a)
            pp = val_pos_a;
        else if (sel_pos_2a)
            pp = val_pos_2a;
        else if (sel_neg_2a)
            pp = val_neg_2a;
        else if (sel_neg_a)
            pp = val_neg_a;
        else
            pp = 10'd0;
    end
endmodule