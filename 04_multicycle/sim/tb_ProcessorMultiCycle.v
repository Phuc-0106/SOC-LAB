`timescale 1ns / 1ns

module tb_ProcessorMultiCycle;

    // Clock + reset
    reg clock_proc;
    reg clock_mem;
    reg rst;
    wire halt;

    // Instantiate DUT (Processor top-level)
    Processor dut (
        .clock_proc (clock_proc),
        .clock_mem  (clock_mem),
        .rst        (rst),
        .halt       (halt)
    );

    // Clock parameters
    localparam CLK_PERIOD = 10;      // 10ns -> 100MHz
    localparam HALF       = CLK_PERIOD/2;
    localparam QUARTER    = CLK_PERIOD/4;

    // Tạo clock_proc: 0°, chu kỳ 10ns
    initial begin
        clock_proc = 1'b0;
        forever #(HALF) clock_proc = ~clock_proc;
    end

    // Tạo clock_mem: lệch pha ~90° so với clock_proc
    initial begin
        clock_mem = 1'b0;
        #QUARTER;
        forever #(HALF) clock_mem = ~clock_mem;
    end

    // Dump waveform (nếu cần xem GTKWAVE)
    initial begin
        $dumpfile("processor_mc.vcd");
        $dumpvars(0, tb_ProcessorMultiCycle);
    end

    // Main stimulus
    integer cycle_count;
    integer i;
    reg [31:0] val;

    localparam MAX_CYCLES = 2000;

    initial begin
        // Init
        rst         = 1'b1;
        cycle_count = 0;

        // Giữ reset vài chu kỳ
        repeat (5) @(posedge clock_proc);
        rst = 1'b0;

        // Chạy cho đến khi halt hoặc timeout
        while (!halt && cycle_count < MAX_CYCLES) begin
            @(posedge clock_proc);
            cycle_count = cycle_count + 1;
        end

        if (halt) begin
            $display("==============================================");
            $display("Processor HALTED at cycle %0d", cycle_count);
        end else begin
            $display("==============================================");
            $display("TIMEOUT: no halt after %0d cycles", MAX_CYCLES);
        end

        // In trạng thái PC + counters trong DatapathMultiCycle
        $display("pcCurrent          = 0x%08h", dut.datapath.pcCurrent);
        $display("cycles_current     = %0d",   dut.datapath.cycles_current);
        $display("num_inst_current   = %0d",   dut.datapath.num_inst_current);

        // In Register File: x0..x31
        $display("----------------------------------------------");
        $display("Register File State (RV32):");
        for (i = 0; i < 32; i = i + 1) begin
            val = dut.datapath.rf.regs[i];
            $display("x%0d : 0x%08h | %0d", i, val, $signed(val));
        end
        $display("==============================================");

        $finish;
    end

endmodule
