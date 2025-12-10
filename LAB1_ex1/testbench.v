`timescale 1ns/1ps

module testbench;

    reg clk;
    reg rst;
    reg sw_mode;
    reg btn_sel;
    reg btn_inc;
    reg btn_dec;

    wire [2:0] lightA, lightB;
    wire [3:0] seg_7A, seg_7B;

    // Clock 100 MHz -> period 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset
    initial begin
        rst = 1;
        #100;
        rst = 0;
    end

    // Default inputs
    initial begin
        sw_mode  = 0;
        btn_sel  = 0;
        btn_inc  = 0;
        btn_dec  = 0;
    end

    // Instantiate DUT
    top_module uut (
        .clk(clk), 
        .rst(rst),
        .sw_mode(sw_mode), 
        .btn_sel(btn_sel), 
        .btn_inc(btn_inc), 
        .btn_dec(btn_dec),
        .lightA(lightA), 
        .lightB(lightB),
        .seg_7A(seg_7A), 
        .seg_7B(seg_7B)
    );

    // Get internal signals
    wire tick = uut.tick;
    wire [3:0] counter = uut.counter;
    wire [2:0] state = uut.fsm.state;

    // Monitor output
    always @(posedge tick) begin
        $display("[%0t ns] State=%0d, Counter=%0d, LightA=%b, LightB=%b, seg_7A=%0d, seg_7B=%0d",
                 $time, state, counter, lightA, lightB, seg_7A, seg_7B);
    end

    // Dump waveform
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, testbench);
    end

    // End simulation
    initial begin
        #50000000;
        $display("Simulation completed");
        $finish;
    end

endmodule
