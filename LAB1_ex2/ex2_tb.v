`timescale 1ns/1ps

module ex2_tb();

    reg clk;
    reg rst;
    reg [1:0] sw_mode;
    reg btn_inc;
    reg btn_dec;
    reg btn_sel;

    wire [3:0] led_outA, led_outB, led_outC, led_outD;

    // DUT
    ex2_top uut (
        .clk(clk),
        .rst(rst),
        .sw_mode(sw_mode),
        .btn_inc(btn_inc),
        .btn_dec(btn_dec),
        .btn_sel(btn_sel),
        .led_outA(led_outA),
        .led_outB(led_outB),
        .led_outC(led_outC),
        .led_outD(led_outD)
    );

    // Clock 10ns
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // init
        rst = 1;
        sw_mode = 2'b00;
        btn_inc = 0;
        btn_dec = 0;
        btn_sel = 0;

        // bỏ reset
        #20 rst = 0;

        // chạy mode 0 trong 200 ns
        #200;

        // đổi sang mode 1
        sw_mode = 2'b01;
        #200;

        // bật mode điều chỉnh counter
        sw_mode = 2'b11;

        // nhấn tăng
        btn_inc = 1;
        #20 btn_inc = 0;

        // nhấn giảm
        btn_dec = 1;
        #20 btn_dec = 0;

        // chọn hướng tăng counter_new
        btn_sel = 1;
        #20 btn_sel = 0;

        // chạy thêm chút
        #500;

        $stop;
    end

endmodule
