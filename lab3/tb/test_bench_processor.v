`timescale 1ns / 1ps

module test_bench_processor;

    // --- 1. Khai báo tín hiệu ---
    reg  clock_proc;
    reg  clock_mem;
    reg  rst;
    wire halt;

    // Tham số thời gian
    parameter NUM_WORDS      = 512;
    parameter CLK_PERIOD     = 4;        // 4ns
    parameter TIMEOUT_CYCLES = 100000;   // tránh chạy vô hạn

    // --- Biến đếm và biến tạm để check ---
    integer cycle_count;
    integer i;

    // Lưu giá trị thanh ghi để so sánh
    reg [31:0] x1_val,  x2_val,  x3_val,  x4_val,  x5_val;
    reg [31:0] x6_val,  x7_val,  x8_val,  x9_val,  x10_val, x11_val;
    reg [31:0] x12_val, x13_val, x14_val, x15_val, x16_val, x17_val, x18_val;
    reg [31:0] x26_val, x27_val, x28_val, x29_val, x30_val, x31_val;

    reg        pass;

    // --- 2. Kết nối với Processor (DUT) ---
    Processor uut (
        .clock_proc (clock_proc),
        .clock_mem  (clock_mem),
        .rst        (rst),
        .halt       (halt)
    );

    // --- 3. Tạo clock ---
    // Clock Processor
    initial begin
        clock_proc = 1'b1; // start_high = True
        forever #(CLK_PERIOD/2) clock_proc = ~clock_proc;
    end

    // Clock Memory lệch pha 90°
    initial begin
        clock_mem = 1'b0;
        #(CLK_PERIOD/4); // lệch 1/4 chu kỳ
        forever #(CLK_PERIOD/2) clock_mem = ~clock_mem;
    end

    // --- 4. Reset + dump waveform ---
    initial begin
        // Waveform
        $dumpfile("test_bench_processor.vcd");
        $dumpvars(0, test_bench_processor.uut);

        // Khởi tạo
        rst         = 1'b1;
        cycle_count = 0;

        // Giữ reset trong vài chu kỳ
        @(posedge clock_proc);
        repeat (2) @(posedge clock_proc);
        rst = 1'b0;

        $display("--- Simulation Started ---");
    end

    // Đếm cycle, timeout nếu chạy quá lâu
    always @(posedge clock_proc) begin
        if (rst) begin
            cycle_count <= 0;
        end else begin
            cycle_count <= cycle_count + 1;
            if (cycle_count >= TIMEOUT_CYCLES) begin
                $display("ERROR: Simulation Timed Out after %0d cycles!", TIMEOUT_CYCLES);
                $finish;
            end
        end
    end

    // --- 5. Kiểm tra kết quả khi halt ---
    initial begin
        // Chờ bỏ reset xong rồi mới chờ halt
        @(negedge rst);
        wait (halt == 1'b1);   // đợi CPU assert halt

        $display("\nProcessor HALTED at cycle %0d", cycle_count);
        $display("---------------------------------------------------");
        $display("State of Register File:");
        for (i = 0; i < 32; i = i + 1) begin
            $display("x%0d  = %h (Dec: %0d)", 
                     i, uut.datapath.rf.regs[i], uut.datapath.rf.regs[i]);
        end
        $display("---------------------------------------------------");

        // ========================================================
        //  FIXED TEST CASE (TB4) – RISC-V SINGLE CYCLE
        //
        //  ASM (tóm tắt):
        //  ------------------------------------------------
        //  CASE 1–3: ALU cơ bản
        //    addi x1, x0, 10       ; x1 = 10
        //    addi x2, x0, 20       ; x2 = 20
        //    add  x3, x1, x2       ; x3 = 30
        //    sub  x4, x3, x1       ; x4 = 20
        //    sub  x5, x1, x2       ; x5 = -10
        //    addi x6, x0, -5       ; x6 = -5
        //    add  x7, x6, x1       ; x7 = 5
        //
        //  CASE 4–5: LUI, AUIPC (x9 sau đó bị ghi đè nên chỉ check value cuối)
        //    lui  x8, 0x12345      ; x8 = 0x12345000
        //    auipc x9, 1           ; x9 = PC + 0x1000 (bị ghi đè sau này)
        //
        //  CASE 6–9: LOAD/STORE với base = 0x400 (1024)
        //    addi x1, x0, 1024     ; x1 = 1024
        //    addi x2, x0, 555      ; x2 = 555
        //    sw   x2, 0(x1)        ; Mem[1024] = 555
        //    lw   x3, 0(x1)        ; x3 = 555
        //
        //    addi x4, x1, 100      ; x4 = 1124 = 0x400 + 100
        //    addi x5, x0, -1       ; x5 = 0xFFFFFFFF
        //    sb   x5, 0(x4)        ; Mem[1124] = 0xFF
        //    lb   x6, 0(x4)        ; x6 = 0xFFFFFFFF (sign-extend)
        //    lbu  x7, 0(x4)        ; x7 = 0x000000FF
        //
        //    addi x8, x1, 200      ; x8 = 1224 = 0x400 + 200
        //    lui  x9, 0x1          ; x9 = 0x00001000
        //    addi x9, x9, 0x234    ; x9 = 0x00001234
        //    sh   x9, 0(x8)        ; Mem[1224..1225] = 0x34, 0x12
        //    lh   x10, 0(x8)       ; x10 = 0x00001234
        //
        //    sw   x2, 4(x1)        ; Mem[1028] = 555
        //    lw   x11, 4(x1)       ; x11 = 555
        //
        //  CASE 10: BRANCH + JUMP
        //  10.1 BEQ (taken, skip x30)
        //    addi x1, x0, 5
        //    addi x2, x0, 5
        //    beq  x1, x2, 8        ; nhảy qua addi x30
        //    addi x30, x0, 999     ; SKIP, nên x30=0
        //    addi x12, x0, 10      ; x12 = 10
        //
        //  10.2 BNE (taken, skip x31)
        //    addi x5, x0, 100      ; x5 = 100
        //    addi x6, x0, 200      ; x6 = 200
        //    bne  x5, x6, 8        ; nhảy qua addi x31
        //    addi x31, x0, 999     ; SKIP, nên x31=0
        //    addi x13, x0, 20      ; x13 = 20
        //
        //  10.3 JAL (skip x28, x29)
        //    jal  x14, 12          ; x14 = PC+4, nhảy qua 2 lệnh tiếp theo
        //    addi x28, x0, 999     ; SKIP, x28=0
        //    addi x29, x0, 999     ; SKIP, x29=0
        //    addi x15, x0, 30      ; x15 = 30
        //
        //  10.4 JALR (skip x27, x26)
        //    auipc x16, 0
        //    addi  x16, x16, 20    ; x16 chứa địa chỉ TARGET
        //    jalr  x17, 0(x16)     ; jump tới TARGET, x17 = PC+4
        //    addi  x27, x0, 999    ; SKIP, x27=0
        //    addi  x26, x0, 999    ; SKIP, x26=0
        //
        //  TARGET:
        //    addi  x18, x0, 40     ; x18 = 40
        //
        //  ------------------------------------------------
        //  GIÁ TRỊ KỲ VỌNG CUỐI CÙNG (sau khi chạy hết chương trình):
        //
        //    x1  = 5
        //    x2  = 5
        //    x3  = 555
        //    x4  = 1124          (0x00000464)
        //    x5  = 100
        //    x6  = 200
        //    x7  = 255           (0x000000FF)
        //    x8  = 1224          (0x000004C8)
        //    x9  = 0x00001234
        //    x10 = 0x00001234
        //    x11 = 555
        //    x12 = 10
        //    x13 = 20
        //    x14 = PC+4 tại lệnh JAL (không check cứng nếu PC base khác)
        //    x15 = 30
        //    x16 = địa chỉ TARGET (PC+20), không check cụ thể
        //    x17 = PC+4 tại lệnh JALR (không check cứng nếu PC base khác)
        //    x18 = 40
        //
        //    x26 = 0   (bị SKIP bởi JALR)
        //    x27 = 0   (bị SKIP bởi JALR)
        //    x28 = 0   (bị SKIP bởi JAL)
        //    x29 = 0   (bị SKIP bởi JAL)
        //    x30 = 0   (bị SKIP bởi BEQ)
        //    x31 = 0   (bị SKIP bởi BNE)
        //
        //  Lưu ý: nếu PC của bạn không bắt đầu từ 0, bạn chỉ cần sửa lại
        //  phần check x14/x17 cho đúng địa chỉ return, hoặc bỏ qua không check.
        // ========================================================

        // Lấy giá trị thanh ghi từ RegFile
        x1_val  = uut.datapath.rf.regs[1];
        x2_val  = uut.datapath.rf.regs[2];
        x3_val  = uut.datapath.rf.regs[3];
        x4_val  = uut.datapath.rf.regs[4];
        x5_val  = uut.datapath.rf.regs[5];
        x6_val  = uut.datapath.rf.regs[6];
        x7_val  = uut.datapath.rf.regs[7];
        x8_val  = uut.datapath.rf.regs[8];
        x9_val  = uut.datapath.rf.regs[9];
        x10_val = uut.datapath.rf.regs[10];
        x11_val = uut.datapath.rf.regs[11];
        x12_val = uut.datapath.rf.regs[12];
        x13_val = uut.datapath.rf.regs[13];
        x14_val = uut.datapath.rf.regs[14];
        x15_val = uut.datapath.rf.regs[15];
        x16_val = uut.datapath.rf.regs[16];
        x17_val = uut.datapath.rf.regs[17];
        x18_val = uut.datapath.rf.regs[18];

        x26_val = uut.datapath.rf.regs[26];
        x27_val = uut.datapath.rf.regs[27];
        x28_val = uut.datapath.rf.regs[28];
        x29_val = uut.datapath.rf.regs[29];
        x30_val = uut.datapath.rf.regs[30];
        x31_val = uut.datapath.rf.regs[31];

        // Bắt đầu so sánh
        pass = 1'b1;

        // --- ALU + LOAD/STORE + BRANCH RESULTS ---

        // x1 = 5
        if (x1_val !== 32'd5) begin
            $display("FAIL: x1 expected 00000005 (5), got %h", x1_val);
            pass = 1'b0;
        end

        // x2 = 5
        if (x2_val !== 32'd5) begin
            $display("FAIL: x2 expected 00000005 (5), got %h", x2_val);
            pass = 1'b0;
        end

        // x3 = 555
        if (x3_val !== 32'd555) begin
            $display("FAIL: x3 expected 0000022B (555), got %h", x3_val);
            pass = 1'b0;
        end

        // x4 = 1124 (1024 + 100)
        if (x4_val !== 32'd1124) begin
            $display("FAIL: x4 expected 00000464 (1124), got %h", x4_val);
            pass = 1'b0;
        end

        // x5 = 100 (sau BNE)
        if (x5_val !== 32'd100) begin
            $display("FAIL: x5 expected 00000064 (100), got %h", x5_val);
            pass = 1'b0;
        end

        // x6 = 200 (sau BNE)
        if (x6_val !== 32'd200) begin
            $display("FAIL: x6 expected 000000C8 (200), got %h", x6_val);
            pass = 1'b0;
        end

        // x7 = 255 (LBU)
        if (x7_val !== 32'h000000FF) begin
            $display("FAIL: x7 expected 000000FF (255, LBU), got %h", x7_val);
            pass = 1'b0;
        end

        // x8 = 1224 (1024 + 200)
        if (x8_val !== 32'd1224) begin
            $display("FAIL: x8 expected 000004C8 (1224), got %h", x8_val);
            pass = 1'b0;
        end

        // x9 = 0x00001234 (LUI + ADDI)
        if (x9_val !== 32'h00001234) begin
            $display("FAIL: x9 expected 00001234, got %h", x9_val);
            pass = 1'b0;
        end

        // x10 = 0x00001234 (LH)
        if (x10_val !== 32'h00001234) begin
            $display("FAIL: x10 expected 00001234 (LH), got %h", x10_val);
            pass = 1'b0;
        end

        // x11 = 555 (SW/LW offset 4)
        if (x11_val !== 32'd555) begin
            $display("FAIL: x11 expected 0000022B (555), got %h", x11_val);
            pass = 1'b0;
        end

        // x12 = 10 (BEQ taken, thực thi addi x12)
        if (x12_val !== 32'd10) begin
            $display("FAIL: x12 expected 0000000A (10), got %h", x12_val);
            pass = 1'b0;
        end

        // x13 = 20 (BNE taken, thực thi addi x13)
        if (x13_val !== 32'd20) begin
            $display("FAIL: x13 expected 00000014 (20), got %h", x13_val);
            pass = 1'b0;
        end

        // x15 = 30 (sau JAL, addi x15)
        if (x15_val !== 32'd30) begin
            $display("FAIL: x15 expected 0000001E (30), got %h", x15_val);
            pass = 1'b0;
        end

        // x18 = 40 (TARGET của JALR)
        if (x18_val !== 32'd40) begin
            $display("FAIL: x18 expected 00000028 (40), got %h", x18_val);
            pass = 1'b0;
        end

        // --- Kiểm tra SKIP của branch/jump ---

        if (x30_val !== 32'd0) begin
            $display("FAIL: x30 expected 00000000 (BEQ should skip), got %h", x30_val);
            pass = 1'b0;
        end

        if (x31_val !== 32'd0) begin
            $display("FAIL: x31 expected 00000000 (BNE should skip), got %h", x31_val);
            pass = 1'b0;
        end

        if (x28_val !== 32'd0) begin
            $display("FAIL: x28 expected 00000000 (JAL should skip), got %h", x28_val);
            pass = 1'b0;
        end

        if (x29_val !== 32'd0) begin
            $display("FAIL: x29 expected 00000000 (JAL should skip), got %h", x29_val);
            pass = 1'b0;
        end

        if (x27_val !== 32'd0) begin
            $display("FAIL: x27 expected 00000000 (JALR should skip), got %h", x27_val);
            pass = 1'b0;
        end

        if (x26_val !== 32'd0) begin
            $display("FAIL: x26 expected 00000000 (JALR should skip), got %h", x26_val);
            pass = 1'b0;
        end

        // --- (Tùy chọn) check link register nếu PC bắt đầu từ 0 ---
        // Với PC khởi tạo = 0, mỗi lệnh 4 byte, thì:
        //   - jal ở PC = 140 (0x0000008C), x14 = PC+4 = 0x00000090
        //   - jalr ở PC = 164 (0x000000A4), x17 = PC+4 = 0x000000A8
        //
        // Nếu kiến trúc PC của bạn khác, có thể bỏ comment 2 dòng dưới.
        /*
        if (x14_val !== 32'h00000090) begin
            $display("FAIL: x14 expected 00000090 (RA of JAL), got %h", x14_val);
            pass = 1'b0;
        end

        if (x17_val !== 32'h000000A8) begin
            $display("FAIL: x17 expected 000000A8 (RA of JALR), got %h", x17_val);
            pass = 1'b0;
        end
        */

        // --- Tổng kết ---
        if (pass) begin
            $display("==================================================");
            $display("RESULT: TB4 – FULL RISC-V CPU TEST PASSED");
            $display("==================================================");
        end else begin
            $display("==================================================");
            $display("RESULT: TB4 – FULL RISC-V CPU TEST FAILED");
            $display("==================================================");
        end

        #1000;
        $finish;
    end

endmodule
