// 10-Bit FPGA Fabric-Aware Adder
`timescale 1ns / 1ps

(* keep_hierarchy = "yes" *)
module fpga_aware_adder_10bit (
    input  wire [9:0] a,
    input  wire [9:0] b,
    input  wire       cin,
    output wire [9:0] sum,
    output wire       cout
);
    wire c8;
    fpga_aware_adder8 u_lo8 (
        .a(a[7:0]), .b(b[7:0]), .cin(cin), .sum(sum[7:0]), .cout(c8)
    );

    wire p8, p9;
    LUT6_2 #(.INIT(64'h0FF00FF066666666)) u_lut_p89 (
        .O5(p8), .O6(p9),
        .I0(a[8]), .I1(b[8]), .I2(a[9]), .I3(b[9]), .I4(1'b0), .I5(1'b1)
    );

    wire [3:0] c_top, sum_top;
    CARRY4 u_carry_top (
        .CO    (c_top),
        .O     (sum_top),
        .CI    (c8),
        .CYINIT(1'b0),
        .DI    ({2'b00, a[9:8]}),
        .S     ({2'b00, p9, p8})
    );

    assign sum[9:8] = sum_top[1:0];
    assign cout     = c_top[1];

endmodule