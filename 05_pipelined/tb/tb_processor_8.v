`timescale 1ns / 1ns

`define REG_SIZE 31
`define INST_SIZE 31

// ANSI Colors
`define RED     "\033[1;31m"
`define GREEN   "\033[1;32m"
`define YELLOW  "\033[1;33m"
`define BLUE    "\033[1;34m"
`define RESET   "\033[0m"

module tb_processor_8;

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

  // Task check 1 thanh ghi — có màu
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
      $display({`BLUE, "---------- CHECKING REGISTERS (CASE8) ----------", `RESET});

      check_reg(0,  32'h00000000);

      check_reg(1,  32'h00000005);
      check_reg(2,  32'h00000005);
      check_reg(3,  32'h00000000);
      check_reg(4,  32'h0000000a);
      check_reg(5,  32'h00000064);
      check_reg(6,  32'h00000064);
      check_reg(7,  32'h00000000);
      check_reg(8,  32'h0000002a);

      for (i = 9; i < 32; i = i + 1)
        check_reg(i, 32'h00000000);

      $display({`BLUE, "------------------------------------------------", `RESET});
    end
  endtask

  initial begin
    cycle = 0;
    err   = 0;

    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    $display({`YELLOW, "============================================", `RESET});
    $display({`YELLOW, "  tb_processor_8: CASE8 - Branch + Load-Use", `RESET});
    $display({`YELLOW, "============================================", `RESET});

    while (cycle < TIMEOUT_CYCLES && !halt) begin
      @(posedge clk);
      cycle = cycle + 1;

      if (trace_pc != 32'd0)
        $display("Cycle %0d: WB pc = 0x%08x, inst = 0x%08x",
                 cycle, trace_pc, trace_inst);
    end

    if (halt)
      $display({`GREEN, "Processor HALTED at cycle %0d", `RESET}, cycle);
    else
      $display({`RED, "TIMEOUT at cycle %0d (halt==0)", `RESET}, cycle);

    run_checks();

    if (err == 0)
      $display({`GREEN, "==== CASE8 PASS ====", `RESET});
    else
      $display({`RED, "==== CASE8 FAIL, err = %0d ====", `RESET}, err);

    $finish;
  end

  initial begin
    $dumpfile("pipelined_processor_8.vcd");
    $dumpvars(0, tb_processor_8);
  end

endmodule
