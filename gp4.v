`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/29/2025 07:41:23 AM
// Design Name: 
// Module Name: gp8
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// gp4.v
module gp4 (
    input  wire [3:0] g,    // g[0] is for LSB of this 4-bit window
    input  wire [3:0] p,
    input  wire c0,         // carry-in for this 4-bit window
    output wire [3:1] c,    // c[1], c[2], c[3] (relative to this window)
    output wire G_group,    // generate for whole 4-bit window
    output wire P_group     // propagate for whole 4-bit window
);

    // internal carries computed from bit-level g/p (using expanded formulas)
    assign c[1] = g[0] | (p[0] & c0);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c0);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c0);

    // Group generate / propagate
    assign G_group = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign P_group = &p; // reduction AND: p3 & p2 & p1 & p0

endmodule
