`timescale 1ns / 1ns
`define REG_SIZE 31
`define INST_SIZE 31

module tb_processor_2;

  reg  clk;
  reg  rst;
  wire halt;
  wire [`REG_SIZE:0] trace_pc;
  wire [`INST_SIZE:0] trace_inst;

  parameter CLK_PERIOD     = 4;
  parameter TIMEOUT_CYCLES = 200;

  integer cycle;
  integer err;

  Processor uut (
    .clk                 (clk),
    .rst                 (rst),
    .halt                (halt),
    .trace_writeback_pc  (trace_pc),
    .trace_writeback_inst(trace_inst)
  );

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

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
      check_reg(1, 32'h00000001);
      check_reg(2, 32'h00000008);
      check_reg(3, 32'h00000400);
      check_reg(4, 32'hfffffff0);
      check_reg(5, 32'h3ffffffc);
      check_reg(6, 32'hfffffffc);
    end
  endtask

  initial begin
    cycle = 0;
    err   = 0;

    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    $display("============================================");
    $display("  tb_processor_2: CASE2 - Shift ops");
    $display("============================================");

    while (cycle < TIMEOUT_CYCLES && !halt) begin
      @(posedge clk);
      cycle = cycle + 1;
      if (trace_pc != 0) begin
        $display("Cycle %0d: WB pc = 0x%08x, inst = 0x%08x",
                 cycle, trace_pc, trace_inst);
      end
    end

    run_checks();

    if (err == 0)
      $display("==== CASE2 PASS ====");
    else
      $display("==== CASE2 FAIL, err = %0d ====", err);

    $finish;
  end

  initial begin
    $dumpfile("pipelined_processor_2.vcd");
    $dumpvars(0, tb_processor_2);
  end

endmodule
