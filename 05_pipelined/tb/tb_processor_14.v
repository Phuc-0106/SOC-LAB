`timescale 1ns / 1ns

`define REG_SIZE 31
`define INST_SIZE 31

// ANSI Colors
`define RED     "\033[1;31m"
`define GREEN   "\033[1;32m"
`define YELLOW  "\033[1;33m"
`define BLUE    "\033[1;34m"
`define RESET   "\033[0m"

module tb_processor_14;

  reg  clk;
  reg  rst;
  wire halt;
  wire [`REG_SIZE:0]  trace_pc;
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

  // Task: check 1 thanh ghi — có màu
  task check_reg(
    input integer idx,
    input [31:0] exp
  );
    reg [31:0] got;
    begin
      got = uut.datapath.rf.regs[idx];
      if (got !== exp) begin
        $display({`RED, "ERROR: x%0d expected=0x%08x, got=0x%08x", `RESET},
                 idx, exp, got);
        err = err + 1;
      end else begin
        $display({`GREEN, "OK   : x%0d = 0x%08x", `RESET},
                 idx, got);
      end
    end
  endtask

  task run_checks;
    begin
      $display({`BLUE, "---------- CHECKING REGISTERS (CASE14) ----------", `RESET});

      // Chương trình assembly:
      //   addi x1, x0, 1
      //   add  x2, x1, x1     # 2
      //   add  x3, x2, x2     # 4
      //   add  x4, x3, x3     # 8
      //   add  x5, x4, x4     # 16
      //   add  x6, x5, x5     # 32
      //
      // Kỳ vọng:
      //   x0 = 0
      //   x1 = 1
      //   x2 = 2
      //   x3 = 4
      //   x4 = 8
      //   x5 = 16
      //   x6 = 32
      //   x7..x31 = 0

      check_reg(0, 32'h00000000); // x0 = 0

      check_reg(1, 32'h00000001); // x1 = 1
      check_reg(2, 32'h00000002); // x2 = 2
      check_reg(3, 32'h00000004); // x3 = 4
      check_reg(4, 32'h00000008); // x4 = 8
      check_reg(5, 32'h00000010); // x5 = 16
      check_reg(6, 32'h00000020); // x6 = 32

      // Các thanh ghi còn lại phải = 0
      for (i = 7; i < 32; i = i + 1)
        check_reg(i, 32'h00000000);

      $display({`BLUE, "------------------------------------------------", `RESET});
    end
  endtask

  initial begin
    cycle = 0;
    err   = 0;

    // Reset
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    $display({`YELLOW, "============================================", `RESET});
    $display({`YELLOW, "  tb_processor_14: CASE14 - ALU Doubling Chain", `RESET});
    $display({`YELLOW, "============================================", `RESET});

    // Run tới khi halt hoặc timeout
    while (cycle < TIMEOUT_CYCLES && !halt) begin
      @(posedge clk);
      cycle = cycle + 1;

      if (trace_pc != 32'd0) begin
        $display("Cycle %0d: WB pc = 0x%08x, inst = 0x%08x",
                 cycle, trace_pc, trace_inst);
      end
    end

    if (halt)
      $display({`GREEN, "Processor HALTED at cycle %0d", `RESET}, cycle);
    else
      $display({`RED, "TIMEOUT at cycle %0d (halt==0)", `RESET}, cycle);

    // Check register file
    run_checks();

    if (err == 0)
      $display({`GREEN, "==== CASE14 PASS ====", `RESET});
    else
      $display({`RED, "==== CASE14 FAIL, err = %0d ====", `RESET}, err);

    $finish;
  end

  // VCD
  initial begin
    $dumpfile("pipelined_processor_14.vcd");
    $dumpvars(0, tb_processor_14);
  end

endmodule
