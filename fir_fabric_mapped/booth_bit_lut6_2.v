// Radix-4 Booth Group Partial Product Generator (10-bit Signed Output)
`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module booth_radix4_group (
    input  wire signed [7:0] a,
    input  wire              b_prev, // B(2k-1)
    input  wire              b_curr, // B(2k)
    input  wire              b_next, // B(2k+1)
    output reg  signed [9:0] pp      // 10-bit signed partial product
);
    wire [2:0] grp = {b_next, b_curr, b_prev};

    always @(*) begin
        case (grp)
            3'b000, 3'b111: pp = 10'sd0;
            3'b001, 3'b010: pp = {{2{a[7]}}, a};           // +1 * A
            3'b011:         pp = {{1{a[7]}}, a, 1'b0};     // +2 * A
            3'b100:         pp = -({{1{a[7]}}, a, 1'b0});  // -2 * A
            3'b101, 3'b110: pp = -({{2{a[7]}}, a});        // -1 * A
            default:        pp = 10'sd0;
        endcase
    end
endmodule