

`timescale 1ns / 1ns

// quotient = dividend / divisor

module DividerUnsignedPipelined (
    input             clk, rst, stall,
    input      [31:0] i_dividend,
    input      [31:0] i_divisor,
    output reg [31:0] o_remainder,
    output reg [31:0] o_quotient
);

  // ----------------------------------------------------
  // 1. Thanh ghi pipeline 8 stage
  // ----------------------------------------------------
  reg [31:0] stage_dividend [0:7];
  reg [31:0] stage_divisor  [0:7];
  reg [31:0] stage_remainder[0:7];
  reg [31:0] stage_quotient [0:7];

  integer i;

  // ----------------------------------------------------
  // 2. Stage 0: xử lý bit 31..28 của i_dividend
  // ----------------------------------------------------
  wire [31:0] s0_r0, s0_r1, s0_r2, s0_r3, s0_r4;
  wire [31:0] s0_q0, s0_q1, s0_q2, s0_q3, s0_q4;
  wire        s0_qb0, s0_qb1, s0_qb2, s0_qb3;

  assign s0_r0 = 32'd0;
  assign s0_q0 = 32'd0;

  // bit 31
  divu_1iter u0_0 (
      .dividend_bit (i_dividend[31]),
      .divisor_in   (i_divisor),
      .remainder_in (s0_r0),
      .remainder_out(s0_r1),
      .quotient_bit (s0_qb0)
  );
  assign s0_q1 = {s0_q0[30:0], s0_qb0};

  // bit 30
  divu_1iter u0_1 (
      .dividend_bit (i_dividend[30]),
      .divisor_in   (i_divisor),
      .remainder_in (s0_r1),
      .remainder_out(s0_r2),
      .quotient_bit (s0_qb1)
  );
  assign s0_q2 = {s0_q1[30:0], s0_qb1};

  // bit 29
  divu_1iter u0_2 (
      .dividend_bit (i_dividend[29]),
      .divisor_in   (i_divisor),
      .remainder_in (s0_r2),
      .remainder_out(s0_r3),
      .quotient_bit (s0_qb2)
  );
  assign s0_q3 = {s0_q2[30:0], s0_qb2};

  // bit 28
  divu_1iter u0_3 (
      .dividend_bit (i_dividend[28]),
      .divisor_in   (i_divisor),
      .remainder_in (s0_r3),
      .remainder_out(s0_r4),
      .quotient_bit (s0_qb3)
  );
  assign s0_q4 = {s0_q3[30:0], s0_qb3};

  wire [31:0] stage0_remainder_next = s0_r4;
  wire [31:0] stage0_quotient_next  = s0_q4;
  wire [31:0] stage0_dividend_next  = i_dividend;
  wire [31:0] stage0_divisor_next   = i_divisor;

  // ----------------------------------------------------
  // 3. Stage 1: xử lý bit 27..24
  // ----------------------------------------------------
  wire [31:0] s1_r0, s1_r1, s1_r2, s1_r3, s1_r4;
  wire [31:0] s1_q0, s1_q1, s1_q2, s1_q3, s1_q4;
  wire        s1_qb0, s1_qb1, s1_qb2, s1_qb3;

  assign s1_r0 = stage_remainder[0];
  assign s1_q0 = stage_quotient[0];

  // bit 27
  divu_1iter u1_0 (
      .dividend_bit (stage_dividend[0][27]),
      .divisor_in   (stage_divisor[0]),
      .remainder_in (s1_r0),
      .remainder_out(s1_r1),
      .quotient_bit (s1_qb0)
  );
  assign s1_q1 = {s1_q0[30:0], s1_qb0};

  // bit 26
  divu_1iter u1_1 (
      .dividend_bit (stage_dividend[0][26]),
      .divisor_in   (stage_divisor[0]),
      .remainder_in (s1_r1),
      .remainder_out(s1_r2),
      .quotient_bit (s1_qb1)
  );
  assign s1_q2 = {s1_q1[30:0], s1_qb1};

  // bit 25
  divu_1iter u1_2 (
      .dividend_bit (stage_dividend[0][25]),
      .divisor_in   (stage_divisor[0]),
      .remainder_in (s1_r2),
      .remainder_out(s1_r3),
      .quotient_bit (s1_qb2)
  );
  assign s1_q3 = {s1_q2[30:0], s1_qb2};

  // bit 24
  divu_1iter u1_3 (
      .dividend_bit (stage_dividend[0][24]),
      .divisor_in   (stage_divisor[0]),
      .remainder_in (s1_r3),
      .remainder_out(s1_r4),
      .quotient_bit (s1_qb3)
  );
  assign s1_q4 = {s1_q3[30:0], s1_qb3};

  wire [31:0] stage1_remainder_next = s1_r4;
  wire [31:0] stage1_quotient_next  = s1_q4;
  wire [31:0] stage1_dividend_next  = stage_dividend[0];
  wire [31:0] stage1_divisor_next   = stage_divisor[0];

  // ----------------------------------------------------
  // 4. Stage 2: xử lý bit 23..20
  // ----------------------------------------------------
  wire [31:0] s2_r0, s2_r1, s2_r2, s2_r3, s2_r4;
  wire [31:0] s2_q0, s2_q1, s2_q2, s2_q3, s2_q4;
  wire        s2_qb0, s2_qb1, s2_qb2, s2_qb3;

  assign s2_r0 = stage_remainder[1];
  assign s2_q0 = stage_quotient[1];

  // bit 23
  divu_1iter u2_0 (
      .dividend_bit (stage_dividend[1][23]),
      .divisor_in   (stage_divisor[1]),
      .remainder_in (s2_r0),
      .remainder_out(s2_r1),
      .quotient_bit (s2_qb0)
  );
  assign s2_q1 = {s2_q0[30:0], s2_qb0};

  // bit 22
  divu_1iter u2_1 (
      .dividend_bit (stage_dividend[1][22]),
      .divisor_in   (stage_divisor[1]),
      .remainder_in (s2_r1),
      .remainder_out(s2_r2),
      .quotient_bit (s2_qb1)
  );
  assign s2_q2 = {s2_q1[30:0], s2_qb1};

  // bit 21
  divu_1iter u2_2 (
      .dividend_bit (stage_dividend[1][21]),
      .divisor_in   (stage_divisor[1]),
      .remainder_in (s2_r2),
      .remainder_out(s2_r3),
      .quotient_bit (s2_qb2)
  );
  assign s2_q3 = {s2_q2[30:0], s2_qb2};

  // bit 20
  divu_1iter u2_3 (
      .dividend_bit (stage_dividend[1][20]),
      .divisor_in   (stage_divisor[1]),
      .remainder_in (s2_r3),
      .remainder_out(s2_r4),
      .quotient_bit (s2_qb3)
  );
  assign s2_q4 = {s2_q3[30:0], s2_qb3};

  wire [31:0] stage2_remainder_next = s2_r4;
  wire [31:0] stage2_quotient_next  = s2_q4;
  wire [31:0] stage2_dividend_next  = stage_dividend[1];
  wire [31:0] stage2_divisor_next   = stage_divisor[1];

  // ----------------------------------------------------
  // 5. Stage 3: xử lý bit 19..16
  // ----------------------------------------------------
  wire [31:0] s3_r0, s3_r1, s3_r2, s3_r3, s3_r4;
  wire [31:0] s3_q0, s3_q1, s3_q2, s3_q3, s3_q4;
  wire        s3_qb0, s3_qb1, s3_qb2, s3_qb3;

  assign s3_r0 = stage_remainder[2];
  assign s3_q0 = stage_quotient[2];

  // bit 19
  divu_1iter u3_0 (
      .dividend_bit (stage_dividend[2][19]),
      .divisor_in   (stage_divisor[2]),
      .remainder_in (s3_r0),
      .remainder_out(s3_r1),
      .quotient_bit (s3_qb0)
  );
  assign s3_q1 = {s3_q0[30:0], s3_qb0};

  // bit 18
  divu_1iter u3_1 (
      .dividend_bit (stage_dividend[2][18]),
      .divisor_in   (stage_divisor[2]),
      .remainder_in (s3_r1),
      .remainder_out(s3_r2),
      .quotient_bit (s3_qb1)
  );
  assign s3_q2 = {s3_q1[30:0], s3_qb1};

  // bit 17
  divu_1iter u3_2 (
      .dividend_bit (stage_dividend[2][17]),
      .divisor_in   (stage_divisor[2]),
      .remainder_in (s3_r2),
      .remainder_out(s3_r3),
      .quotient_bit (s3_qb2)
  );
  assign s3_q3 = {s3_q2[30:0], s3_qb2};

  // bit 16
  divu_1iter u3_3 (
      .dividend_bit (stage_dividend[2][16]),
      .divisor_in   (stage_divisor[2]),
      .remainder_in (s3_r3),
      .remainder_out(s3_r4),
      .quotient_bit (s3_qb3)
  );
  assign s3_q4 = {s3_q3[30:0], s3_qb3};

  wire [31:0] stage3_remainder_next = s3_r4;
  wire [31:0] stage3_quotient_next  = s3_q4;
  wire [31:0] stage3_dividend_next  = stage_dividend[2];
  wire [31:0] stage3_divisor_next   = stage_divisor[2];

  // ----------------------------------------------------
  // 6. Stage 4: xử lý bit 15..12
  // ----------------------------------------------------
  wire [31:0] s4_r0, s4_r1, s4_r2, s4_r3, s4_r4;
  wire [31:0] s4_q0, s4_q1, s4_q2, s4_q3, s4_q4;
  wire        s4_qb0, s4_qb1, s4_qb2, s4_qb3;

  assign s4_r0 = stage_remainder[3];
  assign s4_q0 = stage_quotient[3];

  // bit 15
  divu_1iter u4_0 (
      .dividend_bit (stage_dividend[3][15]),
      .divisor_in   (stage_divisor[3]),
      .remainder_in (s4_r0),
      .remainder_out(s4_r1),
      .quotient_bit (s4_qb0)
  );
  assign s4_q1 = {s4_q0[30:0], s4_qb0};

  // bit 14
  divu_1iter u4_1 (
      .dividend_bit (stage_dividend[3][14]),
      .divisor_in   (stage_divisor[3]),
      .remainder_in (s4_r1),
      .remainder_out(s4_r2),
      .quotient_bit (s4_qb1)
  );
  assign s4_q2 = {s4_q1[30:0], s4_qb1};

  // bit 13
  divu_1iter u4_2 (
      .dividend_bit (stage_dividend[3][13]),
      .divisor_in   (stage_divisor[3]),
      .remainder_in (s4_r2),
      .remainder_out(s4_r3),
      .quotient_bit (s4_qb2)
  );
  assign s4_q3 = {s4_q2[30:0], s4_qb2};

  // bit 12
  divu_1iter u4_3 (
      .dividend_bit (stage_dividend[3][12]),
      .divisor_in   (stage_divisor[3]),
      .remainder_in (s4_r3),
      .remainder_out(s4_r4),
      .quotient_bit (s4_qb3)
  );
  assign s4_q4 = {s4_q3[30:0], s4_qb3};

  wire [31:0] stage4_remainder_next = s4_r4;
  wire [31:0] stage4_quotient_next  = s4_q4;
  wire [31:0] stage4_dividend_next  = stage_dividend[3];
  wire [31:0] stage4_divisor_next   = stage_divisor[3];

  // ----------------------------------------------------
  // 7. Stage 5: xử lý bit 11..8
  // ----------------------------------------------------
  wire [31:0] s5_r0, s5_r1, s5_r2, s5_r3, s5_r4;
  wire [31:0] s5_q0, s5_q1, s5_q2, s5_q3, s5_q4;
  wire        s5_qb0, s5_qb1, s5_qb2, s5_qb3;

  assign s5_r0 = stage_remainder[4];
  assign s5_q0 = stage_quotient[4];

  // bit 11
  divu_1iter u5_0 (
      .dividend_bit (stage_dividend[4][11]),
      .divisor_in   (stage_divisor[4]),
      .remainder_in (s5_r0),
      .remainder_out(s5_r1),
      .quotient_bit (s5_qb0)
  );
  assign s5_q1 = {s5_q0[30:0], s5_qb0};

  // bit 10
  divu_1iter u5_1 (
      .dividend_bit (stage_dividend[4][10]),
      .divisor_in   (stage_divisor[4]),
      .remainder_in (s5_r1),
      .remainder_out(s5_r2),
      .quotient_bit (s5_qb1)
  );
  assign s5_q2 = {s5_q1[30:0], s5_qb1};

  // bit 9
  divu_1iter u5_2 (
      .dividend_bit (stage_dividend[4][9]),
      .divisor_in   (stage_divisor[4]),
      .remainder_in (s5_r2),
      .remainder_out(s5_r3),
      .quotient_bit (s5_qb2)
  );
  assign s5_q3 = {s5_q2[30:0], s5_qb2};

  // bit 8
  divu_1iter u5_3 (
      .dividend_bit (stage_dividend[4][8]),
      .divisor_in   (stage_divisor[4]),
      .remainder_in (s5_r3),
      .remainder_out(s5_r4),
      .quotient_bit (s5_qb3)
  );
  assign s5_q4 = {s5_q3[30:0], s5_qb3};

  wire [31:0] stage5_remainder_next = s5_r4;
  wire [31:0] stage5_quotient_next  = s5_q4;
  wire [31:0] stage5_dividend_next  = stage_dividend[4];
  wire [31:0] stage5_divisor_next   = stage_divisor[4];

  // ----------------------------------------------------
  // 8. Stage 6: xử lý bit 7..4
  // ----------------------------------------------------
  wire [31:0] s6_r0, s6_r1, s6_r2, s6_r3, s6_r4;
  wire [31:0] s6_q0, s6_q1, s6_q2, s6_q3, s6_q4;
  wire        s6_qb0, s6_qb1, s6_qb2, s6_qb3;

  assign s6_r0 = stage_remainder[5];
  assign s6_q0 = stage_quotient[5];

  // bit 7
  divu_1iter u6_0 (
      .dividend_bit (stage_dividend[5][7]),
      .divisor_in   (stage_divisor[5]),
      .remainder_in (s6_r0),
      .remainder_out(s6_r1),
      .quotient_bit (s6_qb0)
  );
  assign s6_q1 = {s6_q0[30:0], s6_qb0};

  // bit 6
  divu_1iter u6_1 (
      .dividend_bit (stage_dividend[5][6]),
      .divisor_in   (stage_divisor[5]),
      .remainder_in (s6_r1),
      .remainder_out(s6_r2),
      .quotient_bit (s6_qb1)
  );
  assign s6_q2 = {s6_q1[30:0], s6_qb1};

  // bit 5
  divu_1iter u6_2 (
      .dividend_bit (stage_dividend[5][5]),
      .divisor_in   (stage_divisor[5]),
      .remainder_in (s6_r2),
      .remainder_out(s6_r3),
      .quotient_bit (s6_qb2)
  );
  assign s6_q3 = {s6_q2[30:0], s6_qb2};

  // bit 4
  divu_1iter u6_3 (
      .dividend_bit (stage_dividend[5][4]),
      .divisor_in   (stage_divisor[5]),
      .remainder_in (s6_r3),
      .remainder_out(s6_r4),
      .quotient_bit (s6_qb3)
  );
  assign s6_q4 = {s6_q3[30:0], s6_qb3};

  wire [31:0] stage6_remainder_next = s6_r4;
  wire [31:0] stage6_quotient_next  = s6_q4;
  wire [31:0] stage6_dividend_next  = stage_dividend[5];
  wire [31:0] stage6_divisor_next   = stage_divisor[5];

  // ----------------------------------------------------
  // 9. Stage 7: xử lý bit 3..0
  // ----------------------------------------------------
  wire [31:0] s7_r0, s7_r1, s7_r2, s7_r3, s7_r4;
  wire [31:0] s7_q0, s7_q1, s7_q2, s7_q3, s7_q4;
  wire        s7_qb0, s7_qb1, s7_qb2, s7_qb3;

  assign s7_r0 = stage_remainder[6];
  assign s7_q0 = stage_quotient[6];

  // bit 3
  divu_1iter u7_0 (
      .dividend_bit (stage_dividend[6][3]),
      .divisor_in   (stage_divisor[6]),
      .remainder_in (s7_r0),
      .remainder_out(s7_r1),
      .quotient_bit (s7_qb0)
  );
  assign s7_q1 = {s7_q0[30:0], s7_qb0};

  // bit 2
  divu_1iter u7_1 (
      .dividend_bit (stage_dividend[6][2]),
      .divisor_in   (stage_divisor[6]),
      .remainder_in (s7_r1),
      .remainder_out(s7_r2),
      .quotient_bit (s7_qb1)
  );
  assign s7_q2 = {s7_q1[30:0], s7_qb1};

  // bit 1
  divu_1iter u7_2 (
      .dividend_bit (stage_dividend[6][1]),
      .divisor_in   (stage_divisor[6]),
      .remainder_in (s7_r2),
      .remainder_out(s7_r3),
      .quotient_bit (s7_qb2)
  );
  assign s7_q3 = {s7_q2[30:0], s7_qb2};

  // bit 0
  divu_1iter u7_3 (
      .dividend_bit (stage_dividend[6][0]),
      .divisor_in   (stage_divisor[6]),
      .remainder_in (s7_r3),
      .remainder_out(s7_r4),
      .quotient_bit (s7_qb3)
  );
  assign s7_q4 = {s7_q3[30:0], s7_qb3};

  wire [31:0] stage7_remainder_next = s7_r4;
  wire [31:0] stage7_quotient_next  = s7_q4;
  wire [31:0] stage7_dividend_next  = stage_dividend[6];
  wire [31:0] stage7_divisor_next   = stage_divisor[6];

  // ----------------------------------------------------
  // 10. Cập nhật pipeline + output
  // ----------------------------------------------------
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      for (i = 0; i < 8; i = i + 1) begin
        stage_dividend[i]  <= 32'd0;
        stage_divisor[i]   <= 32'd0;
        stage_remainder[i] <= 32'd0;
        stage_quotient[i]  <= 32'd0;
      end
      o_remainder <= 32'd0;
      o_quotient  <= 32'd0;
    end else if (!stall) begin
      // Stage 0
      stage_dividend[0]  <= stage0_dividend_next;
      stage_divisor[0]   <= stage0_divisor_next;
      stage_remainder[0] <= stage0_remainder_next;
      stage_quotient[0]  <= stage0_quotient_next;

      // Stage 1..7
      stage_dividend[1]  <= stage1_dividend_next;
      stage_divisor[1]   <= stage1_divisor_next;
      stage_remainder[1] <= stage1_remainder_next;
      stage_quotient[1]  <= stage1_quotient_next;

      stage_dividend[2]  <= stage2_dividend_next;
      stage_divisor[2]   <= stage2_divisor_next;
      stage_remainder[2] <= stage2_remainder_next;
      stage_quotient[2]  <= stage2_quotient_next;

      stage_dividend[3]  <= stage3_dividend_next;
      stage_divisor[3]   <= stage3_divisor_next;
      stage_remainder[3] <= stage3_remainder_next;
      stage_quotient[3]  <= stage3_quotient_next;

      stage_dividend[4]  <= stage4_dividend_next;
      stage_divisor[4]   <= stage4_divisor_next;
      stage_remainder[4] <= stage4_remainder_next;
      stage_quotient[4]  <= stage4_quotient_next;

      stage_dividend[5]  <= stage5_dividend_next;
      stage_divisor[5]   <= stage5_divisor_next;
      stage_remainder[5] <= stage5_remainder_next;
      stage_quotient[5]  <= stage5_quotient_next;

      stage_dividend[6]  <= stage6_dividend_next;
      stage_divisor[6]   <= stage6_divisor_next;
      stage_remainder[6] <= stage6_remainder_next;
      stage_quotient[6]  <= stage6_quotient_next;

      stage_dividend[7]  <= stage7_dividend_next;
      stage_divisor[7]   <= stage7_divisor_next;
      stage_remainder[7] <= stage7_remainder_next;
      stage_quotient[7]  <= stage7_quotient_next;

      // Output từ stage cuối
      o_remainder <= stage_remainder[7];
      o_quotient  <= stage_quotient[7];
    end
    // nếu stall = 1: giữ nguyên pipeline & output
  end

endmodule



module divu_1iter(
    input        dividend_bit,      
    input  [31:0] divisor_in,
    input  [31:0] remainder_in,
    output [31:0] remainder_out,
    output        quotient_bit
    );
    
    reg [31:0] remainder_tmp;
    reg quotient_tmp;

    always @(*) begin
        remainder_tmp = (remainder_in << 1) | dividend_bit; 
        if (remainder_tmp < divisor_in) begin
            quotient_tmp = 1'b0;
        end else begin
            quotient_tmp = 1'b1;
            remainder_tmp = remainder_tmp - divisor_in;
        end
    end

    assign remainder_out = remainder_tmp;
    assign quotient_bit  = quotient_tmp;
endmodule



