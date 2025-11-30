`timescale 1ns / 1ps
module cla (
    input  wire [31:0] a, b,
    input  wire        c0,
    output wire [31:0] sum,
    output wire        cout
);
    wire [31:0] g, p;
    wire [3:0]  G8, P8;
    wire [32:0] carry; // carry[0..32]

    assign carry[0] = c0;

    // Tạo g/p cho từng bit
    gp1 gp_inst [31:0] (.a(a), .b(b), .g(g), .p(p));

    // 4 khối gp8 (mỗi khối 8 bit)
    wire [7:1] c_blk0, c_blk1, c_blk2, c_blk3;

    gp8 block0 (g[7:0],   p[7:0],   carry[0],  c_blk0, G8[0], P8[0]);
    gp8 block1 (g[15:8],  p[15:8],  carry[8],  c_blk1, G8[1], P8[1]);
    gp8 block2 (g[23:16], p[23:16], carry[16], c_blk2, G8[2], P8[2]);
    gp8 block3 (g[31:24], p[31:24], carry[24], c_blk3, G8[3], P8[3]);

    // Carry giữa các khối 8-bit
    assign carry[8]  = G8[0] | (P8[0] & carry[0]);
    assign carry[16] = G8[1] | (P8[1] & carry[8]);
    assign carry[24] = G8[2] | (P8[2] & carry[16]);
    assign carry[32] = G8[3] | (P8[3] & carry[24]);

    // Carry nội bộ từng block
    assign carry[7:1]   = c_blk0[7:1];
    assign carry[15:9]  = c_blk1[7:1];
    assign carry[23:17] = c_blk2[7:1];
    assign carry[31:25] = c_blk3[7:1];

    // Tính sum đúng theo từng bit
    assign sum[7:0]    = a[7:0]   ^ b[7:0]   ^ {c_blk0[7:1], carry[0]};
    assign sum[15:8]   = a[15:8]  ^ b[15:8]  ^ {c_blk1[7:1], carry[8]};
    assign sum[23:16]  = a[23:16] ^ b[23:16] ^ {c_blk2[7:1], carry[16]};
    assign sum[31:24]  = a[31:24] ^ b[31:24] ^ {c_blk3[7:1], carry[24]};
    assign cout = carry[32];
endmodule