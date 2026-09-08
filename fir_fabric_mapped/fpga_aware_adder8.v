// 8-Bit FPGA Fabric-Aware Adder (4 LUT6_2 + 2 CARRY4 Primitives)
`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module fpga_aware_adder8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);
    wire [7:0] prop;
    wire [3:0] c_lo;
    wire [3:0] c_hi;

    // -------------------------------------------------------------------------
    // Dual Propagate Generation in LUT6_2 Primitives
    // LUT 0: Propagate(0) on O5, Propagate(1) on O6
    // -------------------------------------------------------------------------
    LUT6_2 #(.INIT(64'h0FF00FF066666666)) u_lut_p01 (
        .O5(prop[0]), .O6(prop[1]),
        .I0(a[0]), .I1(b[0]), .I2(a[1]), .I3(b[1]), .I4(1'b0), .I5(1'b1)
    );

    // LUT 1: Propagate(2) on O5, Propagate(3) on O6
    LUT6_2 #(.INIT(64'h0FF00FF066666666)) u_lut_p23 (
        .O5(prop[2]), .O6(prop[3]),
        .I0(a[2]), .I1(b[2]), .I2(a[3]), .I3(b[3]), .I4(1'b0), .I5(1'b1)
    );

    // LUT 2: Propagate(4) on O5, Propagate(5) on O6
    LUT6_2 #(.INIT(64'h0FF00FF066666666)) u_lut_p45 (
        .O5(prop[4]), .O6(prop[5]),
        .I0(a[4]), .I1(b[4]), .I2(a[5]), .I3(b[5]), .I4(1'b0), .I5(1'b1)
    );

    // LUT 3: Propagate(6) on O5, Propagate(7) on O6
    LUT6_2 #(.INIT(64'h0FF00FF066666666)) u_lut_p67 (
        .O5(prop[6]), .O6(prop[7]),
        .I0(a[6]), .I1(b[6]), .I2(a[7]), .I3(b[7]), .I4(1'b0), .I5(1'b1)
    );

    // -------------------------------------------------------------------------
    // Lower 4-Bit Fast Carry Chain
    // -------------------------------------------------------------------------
    CARRY4 u_carry_lo (
        .CO    (c_lo),
        .O     (sum[3:0]),
        .CI    (cin),
        .CYINIT(1'b0),
        .DI    (a[3:0]),
        .S     (prop[3:0])
    );

    // -------------------------------------------------------------------------
    // Upper 4-Bit Fast Carry Chain (Chained to c_lo[3])
    // -------------------------------------------------------------------------
    CARRY4 u_carry_hi (
        .CO    (c_hi),
        .O     (sum[7:4]),
        .CI    (c_lo[3]),
        .CYINIT(1'b0),
        .DI    (a[7:4]),
        .S     (prop[7:4])
    );

    assign cout = c_hi[3];

endmodule