`timescale 1ns / 1ns

`define REG_SIZE 31
`define INST_SIZE 31

// ANSI Colors
`define RED     "\033[1;31m"
`define GREEN   "\033[1;32m"
`define YELLOW  "\033[1;33m"
`define BLUE    "\033[1;34m"
`define RESET   "\033[0m"

module tb_processor_15;

  reg  clk;
  reg  rst;
  wire halt;
  wire [`REG_SIZE:0]  trace_pc;
  wire [`INST_SIZE:0] trace_inst;

  parameter CLK_PERIOD     = 4;
  parameter TIMEOUT_CYCLES = 400;  // divider cần lâu hơn

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

  // Task check register
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
      $display({`BLUE, "---------- CHECKING REGISTERS (CASE15) ----------", `RESET});

      // Expected values:
      // x1 = 100
      // x2 = 3
      // x3 = 33
      // x4 = 200
      // x5 = 5
      // x6 = 40

      check_reg(0, 32'h00000000);

      check_reg(1, 32'd100);
      check_reg(2, 32'd3);
      check_reg(3, 32'd33);

      check_reg(4, 32'd200);
      check_reg(5, 32'd5);
      check_reg(6, 32'd40);

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
    $display({`YELLOW, "  tb_processor_15: CASE15 - Basic DIV Tests", `RESET});
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

    // Check regs
    run_checks();

    if (err == 0)
      $display({`GREEN, "==== CASE15 PASS ====", `RESET});
    else
      $display({`RED, "==== CASE15 FAIL, err = %0d ====", `RESET}, err);

    $finish;
  end

  // VCD dump
  initial begin
    $dumpfile("pipelined_processor_15.vcd");
    $dumpvars(0, tb_processor_15);
  end

endmodule
