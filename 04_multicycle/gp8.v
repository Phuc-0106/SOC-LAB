`timescale 1ns / 1ps
module gp8 (
    input  wire [7:0] g,      // g[0]..g[7], g[0] là LSB
    input  wire [7:0] p,
    input  wire       c0,     // carry-in cho block 8-bit
    output wire [7:1] c,      // c[1]..c[7]
    output wire       G_group,
    output wire       P_group
);
    // nội bộ cho 2 block gp4
    wire [3:1] c_low, c_high;
    wire G_low, P_low, G_high, P_high;

    // lower 4-bit (bit 0..3)
    gp4 gp4_low (
        .g(g[3:0]),
        .p(p[3:0]),
        .c0(c0),
        .c(c_low),
        .G_group(G_low),
        .P_group(P_low)
    );

    // carry giữa hai gp4
    wire c_mid;
    assign c_mid = G_low | (P_low & c0);

    // upper 4-bit (bit 4..7)
    gp4 gp4_high (
        .g(g[7:4]),
        .p(p[7:4]),
        .c0(c_mid),
        .c(c_high),
        .G_group(G_high),
        .P_group(P_high)
    );

    // mapping carry nội bộ chính xác
    // chú ý: c_low tạo ra carry sau bit0..bit2, gp4_high tạo ra carry sau bit4..bit6
    assign c[3:1] = c_low[3:1];
    assign c[7:4] = {c_high[3:1], c_mid}; // thêm carry ngay trước bit4

    // group generate / propagate toàn block 8-bit
    assign G_group = G_high | (P_high & G_low);
    assign P_group = P_high & P_low;
endmodule