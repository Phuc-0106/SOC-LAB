`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2025 04:43:52 PM
// Design Name: 
// Module Name: Lab1_ex3_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Lab1_ex3_tb;
    reg clk, rst;
    reg [3:0] btn;
    wire [3:0] led;
    
    Lab1_ex3 uut
    (
        .clk(clk),
        .rst(rst),
        .btn(btn),
        .led(led)
    );
    
    initial begin
        clk = 0;
        btn[0] = 0;
        btn[1] = 0;
        btn[2] = 0;
        btn[3] = 0;
        forever #5 clk <= ~clk;
    end
    
    initial begin
        rst = 1;
        btn = 4'b0000;
        #20 rst = 0;

        // Test shift left (BTN1)
        #10 btn[1] = 1; 
        #10 btn[1] = 0;

        // Wait some ticks to see LED shift
        #200;

        // Test pause (BTN3)
        btn[3] = 1;
        #10 btn[3] = 0;

        #100;

        // Test shift right (BTN2)
        btn[2] = 1;
        #10 btn[2] = 0;

        #200;

        // Test reset (BTN0)
        btn[0] = 1;
        #10 btn[0] = 0;

        #2000;
        $stop;
    end

    initial begin
        $monitor("Time=%0t | LED=%b | btn0=%b btn1=%b btn2=%b btn3=%b", $time, led, btn[0], btn[1], btn[2], btn[3]);
    end

endmodule
