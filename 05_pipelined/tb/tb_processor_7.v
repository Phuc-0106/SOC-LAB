`timescale 1ns / 1ns

`define REG_SIZE 31
`define INST_SIZE 31

module tb_processor_7;

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
    .clk                  (clk),
    .rst                  (rst),
    .halt                 (halt),
    .trace_writeback_pc   (trace_pc),
    .trace_writeback_inst (trace_inst)
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
        $display("ERROR: x%0d expected=0x%08x, got=0x%08x",
                 idx, exp, got);
        err = err + 1;
      end else begin
        $display("OK   : x%0d = 0x%08x", idx, got);
      end
    end
  endtask

  task run_checks;
    begin
      $display("---------- CHECKING REGISTERS (CASE7) ----------");

      // x0 luôn = 0
      check_reg(0,  32'h00000000);

      // Expected values từ case7.asm (phiên bản spec-correct)
      // addi x1, x0, 10
      check_reg(1,  32'h0000000a); // 10

      // jal x2, 8 -> link = PC+4 = 8
      check_reg(2,  32'h00000008); // link JAL

      // addi x3, 999: phải bị FLUSH bởi JAL
      check_reg(3,  32'h00000000); // flushed

      // addi x4, 7
      check_reg(4,  32'h00000007); // 7

      // addi x5, 32
      check_reg(5,  32'h00000020); // 32

      // addi x6, 0
      check_reg(6,  32'h00000000); // 0

      // jalr x7, x5, 0 -> link = PC+4 = 28 (0x1C)
      check_reg(7,  32'h0000001c); // 28 = PC+4 của JALR

      // addi x8, 999: phải bị FLUSH bởi JALR
      check_reg(8,  32'h00000000); // flushed

      // addi x9, 30
      check_reg(9,  32'h0000001e); // 30

      // Các thanh ghi còn lại (x10..x31) không dùng → phải = 0
      for (i = 10; i < 32; i = i + 1) begin
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
    $display("  tb_processor_7: CASE7 - JAL/JALR Link Test");
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

    // Sau khi chạy xong, check toàn bộ thanh ghi
    run_checks();

    if (err == 0)
      $display("==== CASE7 PASS ====");
    else
      $display("==== CASE7 FAIL, err = %0d ====", err);

    $finish;
  end

  // VCD
  initial begin
    $dumpfile("pipelined_processor_7.vcd");
    $dumpvars(0, tb_processor_7);
  end

endmodule
