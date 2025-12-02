`timescale 1ns / 1ns

module tb_DividerUnsignedPipelined;

    // Tín hiệu kết nối với DUT
    reg         clk;
    reg         rst;
    reg         stall;
    reg  [31:0] i_dividend;
    reg  [31:0] i_divisor;
    wire [31:0] o_remainder;
    wire [31:0] o_quotient;

    // --- Instantiate DUT ---
    DividerUnsignedPipelined dut (
        .clk        (clk),
        .rst        (rst),
        .stall      (stall),
        .i_dividend (i_dividend),
        .i_divisor  (i_divisor),
        .o_remainder(o_remainder),
        .o_quotient (o_quotient)
    );

    // --- Tạo clock 10ns (100MHz) ---
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // 5ns lên, 5ns xuống => chu kỳ 10ns
    end

    // --- Test sequence ---
    initial begin
        // Khởi tạo
        rst        = 1'b1;
        stall      = 1'b0;
        i_dividend = 32'd0;
        i_divisor  = 32'd1;

        // Giữ reset một lúc
        #20;
        rst = 1'b0;

        // ------------------------------------------------
        // TEST 1: 100 / 7
        // ------------------------------------------------
        @(negedge clk);
        i_dividend = 32'd100;
        i_divisor  = 32'd7;

        // Đợi >= 8 chu kỳ để pipeline “đẩy” kết quả ra stage cuối
        repeat(10) @(posedge clk);

        $display("TEST 1: 100 / 7");
        $display("  quotient  = %0d (expected 14)", o_quotient);
        $display("  remainder = %0d (expected 2)", o_remainder);
        $display("");

        // ------------------------------------------------
        // TEST 2: 37 / 5
        // ------------------------------------------------
        @(negedge clk);
        i_dividend = 32'd37;
        i_divisor  = 32'd5;

        repeat(10) @(posedge clk);

        $display("TEST 2: 37 / 5");
        $display("  quotient  = %0d (expected 7)", o_quotient);
        $display("  remainder = %0d (expected 2)", o_remainder);
        $display("");

        // ------------------------------------------------
        // TEST 3: 0 / 10
        // ------------------------------------------------
        @(negedge clk);
        i_dividend = 32'd0;
        i_divisor  = 32'd10;

        repeat(10) @(posedge clk);

        $display("TEST 3: 0 / 10");
        $display("  quotient  = %0d (expected 0)", o_quotient);
        $display("  remainder = %0d (expected 0)", o_remainder);
        $display("");

        // Kết thúc mô phỏng
        #20;
        $finish;
    end

endmodule
