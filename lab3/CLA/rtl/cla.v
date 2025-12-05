`timescale 1ns / 1ps
module gp1 (
    input  wire a,
    input  wire b,
    output wire g,
    output wire p
);
    assign g = a & b;
    assign p = a | b;
endmodule


module gp4 (
    input  wire [3:0] g,   
    input  wire [3:0] p,
    input  wire c0,         
    output wire [3:1] c,    
    output wire G_group,   
    output wire P_group     
);

    assign c[1] = g[0] | (p[0] & c0);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c0);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c0);

    assign G_group = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign P_group = &p; 

endmodule


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


module cla (
    input  wire [31:0] a, b,
    input  wire        c0,
    output wire [31:0] sum,
    output wire        cout
);
    wire [31:0] g, p;
    wire [3:0]  G8, P8;
    wire [32:0] carry; 

    assign carry[0] = c0;

    gp1 gp_inst [31:0] (.a(a), .b(b), .g(g), .p(p));

    wire [7:1] c_blk0, c_blk1, c_blk2, c_blk3;

    gp8 block0 (g[7:0],   p[7:0],   carry[0],  c_blk0, G8[0], P8[0]);
    gp8 block1 (g[15:8],  p[15:8],  carry[8],  c_blk1, G8[1], P8[1]);
    gp8 block2 (g[23:16], p[23:16], carry[16], c_blk2, G8[2], P8[2]);
    gp8 block3 (g[31:24], p[31:24], carry[24], c_blk3, G8[3], P8[3]);

    assign carry[8]  = G8[0] | (P8[0] & carry[0]);
    assign carry[16] = G8[1] | (P8[1] & carry[8]);
    assign carry[24] = G8[2] | (P8[2] & carry[16]);
    assign carry[32] = G8[3] | (P8[3] & carry[24]);

    assign carry[7:1]   = c_blk0[7:1];
    assign carry[15:9]  = c_blk1[7:1];
    assign carry[23:17] = c_blk2[7:1];
    assign carry[31:25] = c_blk3[7:1];

    assign sum[7:0]    = a[7:0]   ^ b[7:0]   ^ {c_blk0[7:1], carry[0]};
    assign sum[15:8]   = a[15:8]  ^ b[15:8]  ^ {c_blk1[7:1], carry[8]};
    assign sum[23:16]  = a[23:16] ^ b[23:16] ^ {c_blk2[7:1], carry[16]};
    assign sum[31:24]  = a[31:24] ^ b[31:24] ^ {c_blk3[7:1], carry[24]};
    assign cout = carry[32];
endmodule