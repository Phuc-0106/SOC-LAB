`timescale 1ns / 1ns

module tb_processor_12;

  reg clk = 0;
  reg rst = 1;

  wire halt;
  wire [31:0] trace_writeback_pc;
  wire [31:0] trace_writeback_inst;

  integer cycle_count;
  integer err_count;
  integer i;

  // Clock 50% duty, period 4ns (giống các tb khác)
  always #2 clk = ~clk;

  // DUT
  Processor uut (
    .clk                 (clk),
    .rst                 (rst),
    .halt                (halt),
    .trace_writeback_pc  (trace_writeback_pc),
    .trace_writeback_inst(trace_writeback_inst)
  );

  // In trace mỗi lần có writeback hợp lệ
  always @(posedge clk) begin
    if (!rst && trace_writeback_pc != 32'd0) begin
      $display("Cycle %0d: WB pc = 0x%08x, inst = 0x%08x",
               cycle_count, trace_writeback_pc, trace_writeback_inst);
    end
  end

  // Task check 1 thanh ghi
  task check_reg;
    input integer idx;
    input [31:0] exp;
    reg   [31:0] got;
  begin
    got = uut.datapath.rf.regs[idx];
    if (got !== exp) begin
      $display("ERROR: x%0d expected=0x%08x, got=0x%08x", idx, exp, got);
      err_count = err_count + 1;
    end else begin
      $display("OK   : x%0d = 0x%08x", idx, got);
    end
  end
  endtask

  initial begin
    $display("============================================");
    $display("  tb_processor_12: CASE12 - DIV/REM Regression");
    $display("============================================");

    cycle_count = 0;
    err_count   = 0;

    // Reset vài chu kỳ
    rst = 1;
    repeat (3) @(posedge clk);
    rst = 0;

    // Main loop: chờ HALT hoặc timeout
    while (!halt && cycle_count < 500) begin
      @(posedge clk);
      cycle_count = cycle_count + 1;
    end

    if (!halt) begin
      $display("ERROR: Timeout waiting for HALT (cycle=%0d)", cycle_count);
      $finish;
    end

    // Sau khi HALT, check toàn bộ thanh ghi
    $display("============================================");
    $display("  Checking registers after CASE12");
    $display("============================================");

    // x0 luôn 0
    check_reg(0, 32'h00000000);

    // Theo bảng expected đã tính:
    check_reg(1,  32'h00000064); // 100
    check_reg(2,  32'h00000007); // 7
    check_reg(3,  32'h000000ff); // 255
    check_reg(4,  32'h00000010); // 16
    check_reg(5,  32'h0000002a); // 42
    check_reg(6,  32'h00000009); // 9
    check_reg(7,  32'hffffff9c); // -100
    check_reg(8,  32'hfffffff9); // -7
    check_reg(9,  32'hffffffd6); // -42

    check_reg(10, 32'h0000000e); // 14  = 100 / 7
    check_reg(11, 32'h00000002); // 2   = 100 % 7
    check_reg(12, 32'hfffffff2); // -14 = 100 / -7
    check_reg(13, 32'h00000002); // 2   = 100 % -7
    check_reg(14, 32'hfffffff2); // -14 = -100 / 7
    check_reg(15, 32'hfffffffe); // -2  = -100 % 7
    check_reg(16, 32'h0000000e); // 14  = -100 / -7
    check_reg(17, 32'hfffffffe); // -2  = -100 % -7

    check_reg(18, 32'h0000000f); // 15  = 255 / 16 (unsigned)
    check_reg(19, 32'h0000000f); // 15  = 255 % 16 (unsigned)
    check_reg(20, 32'h00000004); // 4   = 42 / 9
    check_reg(21, 32'h00000006); // 6   = 42 % 9 (unsigned)
    check_reg(22, 32'hfffffffc); // -4  = -42 / 9
    check_reg(23, 32'hfffffffa); // -6  = -42 % 9

    check_reg(24, 32'h00000000); // 0 divisor
    check_reg(25, 32'hffffffff); // -1  = DIV  (100 / 0)
    check_reg(26, 32'h00000064); // 100 = REM  (100 % 0)
    check_reg(27, 32'hffffffff); // -1  = DIVU (100 / 0)
    check_reg(28, 32'h00000064); // 100 = REMU (100 % 0)

    check_reg(29, 32'h0000001d); // 29 = 14 + 15
    check_reg(30, 32'h0000000a); // 10 = 4 + 6
    check_reg(31, 32'h00000027); // 39 = 29 + 10

    $display("============================================");
    if (err_count == 0) begin
      $display("==== CASE12 PASS (err = 0) ====");
    end else begin
      $display("==== CASE12 FAIL, err = %0d ====", err_count);
    end
    $display("============================================");

    $finish;
  end

endmodule
