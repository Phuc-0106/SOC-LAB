`timescale 1ns / 1ns

module tb_ProcessorMultiCycle_divider;

  reg clock_proc = 0;
  reg clock_mem  = 0;
  reg rst        = 1;
  wire halt;

  integer cycle_count;
  integer i;
  integer err_count;

  // expected registers
  reg [31:0] exp_reg [0:31];

  // ===============================
  // 1. Tạo clock
  // ===============================
  always #2 clock_proc = ~clock_proc;
  always #2 clock_mem  = ~clock_mem;

  // ===============================
  // 2. Instance Processor
  // ===============================
  Processor dut (
    .clock_proc (clock_proc),
    .clock_mem  (clock_mem),
    .rst        (rst),
    .halt       (halt)
  );

  // ===============================
  // 3. Main test sequence
  // ===============================
  initial begin
    $display("==========================================");
    $display(" Multi-cycle Processor - DIVIDER TEST (case6)");
    $display("==========================================");

    // ---------------------------------
    // Khởi tạo expected từ Python sim
    // ---------------------------------
    // Python case6 output:
    // x0 : 0
    // x1 : 100
    // x2 : 7
    // x3 : 14
    // x4 : 2
    // x5 : 37
    // x6 : 5
    // x7 : 7
    // x8 : 2
    // x9 : 0
    // x10: 10
    // x11: 0
    // x12: 0
    // x13: 1
    // x14: 3
    // x15..x31: 0

    for (i = 0; i < 32; i = i + 1) begin
      exp_reg[i] = 32'd0;
    end
    exp_reg[1]  = 32'd100;
    exp_reg[2]  = 32'd7;
    exp_reg[3]  = 32'd14;
    exp_reg[4]  = 32'd2;
    exp_reg[5]  = 32'd37;
    exp_reg[6]  = 32'd5;
    exp_reg[7]  = 32'd7;
    exp_reg[8]  = 32'd2;
    exp_reg[9]  = 32'd0;
    exp_reg[10] = 32'd10;
    exp_reg[11] = 32'd0;
    exp_reg[12] = 32'd0;
    exp_reg[13] = 32'd1;
    exp_reg[14] = 32'd3;
    // các thanh ghi còn lại giữ 0

    // ---------------------------------
    // Reset
    // ---------------------------------
    clock_proc  = 0;
    clock_mem   = 0;
    rst         = 1;
    cycle_count = 0;
    err_count   = 0;

    #10;
    rst = 0;

    // Chạy cho đến khi halt hoặc timeout
    while (!halt && cycle_count < 500) begin
      @(posedge clock_proc);
      cycle_count = cycle_count + 1;
    end

    $display("Processor kết thúc tại cycle = %0d, halt = %0d", cycle_count, halt);

    // ---------------------------------
    // In snapshot tất cả 32 thanh ghi
    // ---------------------------------
    $display("==========================================");
    $display(" Register snapshot (x0..x31)");
    $display("==========================================");

    for (i = 0; i < 32; i = i + 1) begin
      $display("x%-2d = %0d (0x%08h)", 
               i, 
               dut.datapath.rf.regs[i], 
               dut.datapath.rf.regs[i]);
    end

    // ---------------------------------
    // So sánh với expected từng thanh ghi
    // ---------------------------------
    $display("==========================================");
    $display(" Checking against expected values (case6)");
    $display("==========================================");

    for (i = 0; i < 32; i = i + 1) begin
      if (dut.datapath.rf.regs[i] !== exp_reg[i]) begin
        err_count = err_count + 1;
        $display("FAIL: x%0d expected %0d (0x%08h), got %0d (0x%08h)",
                 i,
                 exp_reg[i], exp_reg[i],
                 dut.datapath.rf.regs[i], dut.datapath.rf.regs[i]);
      end
    end

    if (err_count == 0) begin
      $display("==========================================");
      $display(" PASS: Divider (DIVU/REMU) test (case6)");
      $display("==========================================");
    end else begin
      $display("==========================================");
      $display(" FAIL: Divider test (case6) - %0d register(s) mismatch", err_count);
      $display("==========================================");
    end

    $finish;
  end

endmodule
