`timescale 1ns / 1ps
module gp8 (
    input  wire [7:0] g,      
    input  wire [7:0] p,
    input  wire       c0,     
    output wire [7:1] c,     
    output wire       G_group,
    output wire       P_group
);
    wire [3:1] c_low, c_high;
    wire G_low, P_low, G_high, P_high;

    gp4 gp4_low (
        .g(g[3:0]),
        .p(p[3:0]),
        .c0(c0),
        .c(c_low),
        .G_group(G_low),
        .P_group(P_low)
    );

    wire c_mid;
    assign c_mid = G_low | (P_low & c0);

    gp4 gp4_high (
        .g(g[7:4]),
        .p(p[7:4]),
        .c0(c_mid),
        .c(c_high),
        .G_group(G_high),
        .P_group(P_high)
    );

    assign c[3:1] = c_low[3:1];
    assign c[7:4] = {c_high[3:1], c_mid}; 

    assign G_group = G_high | (P_high & G_low);
    assign P_group = P_high & P_low;
endmodule