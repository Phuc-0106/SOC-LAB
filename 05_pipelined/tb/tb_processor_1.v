`timescale 1ns / 1ns

`define REG_SIZE 31
`define INST_SIZE 31

module tb_processor_1;

  reg  clk;
  reg  rst;
  wire halt;
  wire [`REG_SIZE:0] trace_pc;
  wire [`INST_SIZE:0] trace_inst;

  parameter CLK_PERIOD     = 4;
  parameter TIMEOUT_CYCLES = 200;

  integer cycle;
  integer err;
  integer i;

  // DUT
  Processor uut (
    .clk                 (clk),
    .rst                 (rst),
    .halt                (halt),
    .trace_writeback_pc  (trace_pc),
    .trace_writeback_inst(trace_inst)
  );

  // Clock
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // Task check 1 thanh ghi
  task check_reg(
    input integer idx,
    input [31:0] exp
  );
    reg [31:0] got;
    begin
      got = uut.datapath.rf.regs[idx];
      if (got !== exp) begin
        $display("ERROR: x%0d expected=0x%08x, got=0x%08x", idx, exp, got);
        err = err + 1;
      end else begin
        $display("OK   : x%0d = 0x%08x", idx, got);
      end
    end
  endtask

  task run_checks;
    begin
      $display("---------- CHECKING ALL 32 REGISTERS ----------");

      // x0 luôn = 0
      check_reg(0, 32'h00000000);

      // Expected values từ case1.asm
      check_reg(1,  32'h0000000a);
      check_reg(2,  32'h00000014);
      check_reg(3,  32'h0000001e);
      check_reg(4,  32'hfffffff6);
      check_reg(5,  32'hfffffffb);
      check_reg(6,  32'h00000019);
      check_reg(7,  32'h00000014);
      check_reg(8,  32'hffffffff);
      check_reg(9,  32'h0000001e);
      check_reg(10, 32'h00000001);
      check_reg(11, 32'h00000000);

      // Các thanh ghi còn lại (x12..x31) không dùng → phải = 0
      for (i = 12; i < 32; i = i + 1) begin
        check_reg(i, 32'h00000000);
      end

      $display("------------------------------------------------");
    end
  endtask

  initial begin
    cycle = 0;
    err   = 0;

    // Reset
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    $display("============================================");
    $display("  tb_processor_1: CASE1 - Basic ALU");
    $display("============================================");

    while (cycle < TIMEOUT_CYCLES && !halt) begin
      @(posedge clk);
      cycle = cycle + 1;

      if (trace_pc != 32'd0) begin
        $display("Cycle %0d: WB pc = 0x%08x, inst = 0x%08x",
                 cycle, trace_pc, trace_inst);
      end
    end

    if (halt)
      $display("Processor HALTED at cycle %0d", cycle);
    else
      $display("TIMEOUT at cycle %0d (halt==0)", cycle);

    // Sau khi chạy xong, check toàn bộ 32 thanh ghi
    run_checks();

    if (err == 0)
      $display("==== CASE1 PASS ====");
    else
      $display("==== CASE1 FAIL, err = %0d ====", err);

    $finish;
  end

  // VCD
  initial begin
    $dumpfile("pipelined_processor_1.vcd");
    $dumpvars(0, tb_processor_1);
  end

endmodule
