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


// gp1.v
module gp1 (
    input  wire a,
    input  wire b,
    output wire g,
    output wire p
);
    assign g = a & b;
    assign p = a | b;
endmodule

