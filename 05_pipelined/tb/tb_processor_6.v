`timescale 1ns / 1ns
`define REG_SIZE 31
`define INST_SIZE 31

module tb_processor_6;

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

  Processor uut (
    .clk                 (clk),
    .rst                 (rst),
    .halt                (halt),
    .trace_writeback_pc  (trace_pc),
    .trace_writeback_inst(trace_inst)
  );

  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  task check_reg(input integer idx, input [31:0] exp);
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
      $display("-------------- Checking Registers --------------");
      check_reg(0,  32'h00000000);
      check_reg(1,  32'h00000005);
      check_reg(2,  32'h00000005);
      check_reg(4,  32'h0000000a);
      check_reg(5,  32'h00000064);
      check_reg(6,  32'h000000c8);
      check_reg(8,  32'h00000014);

      for (i = 9; i < 32; i = i + 1)
        check_reg(i, 32'h00000000);

    end
  endtask

  initial begin
    cycle = 0; err = 0;

    rst = 1; repeat(5) @(posedge clk); rst = 0;

    $display("============================================");
    $display(" CASE6 - Branch & Flush Test");
    $display("============================================");

    while (cycle < TIMEOUT_CYCLES && !halt)
    begin
      @(posedge clk);
      cycle = cycle + 1;

      if (trace_pc != 32'd0)
        $display("Cycle %0d: WB pc = %h, inst = %h",
                  cycle, trace_pc, trace_inst);
    end

    run_checks();

    if (err == 0)
      $display("==== CASE6 PASS ====");
    else
      $display("==== CASE6 FAIL, err = %0d ====", err);

    $finish;
  end

endmodule
