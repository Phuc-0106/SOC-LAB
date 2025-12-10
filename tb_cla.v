`timescale 1ns / 1ps
//-------------------------------------------------------------
// 32-bit Carry Lookahead Adder - Professional Self-Check TB
// Author: (Bạn điền tên của bạn)
// Date  : 2025-10-30
// Purpose: Automatic verification with report + log output
//-------------------------------------------------------------
module tb_cla();

    // ------------------------------
    // DUT I/O
    // ------------------------------
    reg  [31:0] a, b;
    reg         c0;
    wire [31:0] sum;
    wire        cout;

    // Reference (golden model)
    wire [31:0] sum_ref;
    wire        cout_ref;
    assign {cout_ref, sum_ref} = a + b + c0;

    // Instantiate DUT
    cla uut (
        .a(a),
        .b(b),
        .c0(c0),
        .sum(sum),
        .cout(cout)
    );

    // ------------------------------
    // Internal variables
    // ------------------------------
    integer i;
    integer fails = 0;
    integer fd; // file descriptor

    // Test vectors
    reg [31:0] tv_a [0:9];
    reg [31:0] tv_b [0:9];
    reg        tv_c0[0:9];

    // ------------------------------
    // Main test procedure
    // ------------------------------
    initial begin
        // Dump waveform
        $dumpfile("cla_waveform.vcd");
        $dumpvars(0, tb_cla);
        
        $display("\n=======================================================");
        $display("        32-bit CLA SELF-CHECK TESTBENCH (PRO MODE)     ");
        $display("=======================================================");

        fd = $fopen("cla_log.txt", "w");
        if (!fd) begin
            $display("ERROR: Cannot open log file!");
            $finish;
        end

        $fwrite(fd, "================ CLA TEST REPORT ================\n");
        $fwrite(fd, "Time(ns) |   A(hex)    |   B(hex)    | Cin | Sum(hex) | Cout | RefSum(hex) | RefCout | Result\n");
        $fwrite(fd, "------------------------------------------------------------------------------------------\n");

        // ------------------------------
        // 1. Initialize test vectors
        // ------------------------------
        tv_a[0] = 32'h00000000; tv_b[0] = 32'h00000000; tv_c0[0] = 0;
        tv_a[1] = 32'h00000001; tv_b[1] = 32'h00000001; tv_c0[1] = 0;
        tv_a[2] = 32'hFFFFFFFF; tv_b[2] = 32'h00000001; tv_c0[2] = 0;
        tv_a[3] = 32'h12345678; tv_b[3] = 32'h87654321; tv_c0[3] = 1;
        tv_a[4] = 32'hA5A5A5A5; tv_b[4] = 32'h5A5A5A5A; tv_c0[4] = 0;
        tv_a[5] = 32'hDEADBEEF; tv_b[5] = 32'hCAFEBABE; tv_c0[5] = 0;

        // Random tests
        for (i = 6; i < 10; i = i + 1) begin
            tv_a[i]  = $random;
            tv_b[i]  = $random;
            tv_c0[i] = $random & 1;
        end

        // ------------------------------
        // 2. Apply vectors and check results
        // ------------------------------
        for (i = 0; i < 10; i = i + 1) begin
            a  = tv_a[i];
            b  = tv_b[i];
            c0 = tv_c0[i];
            #5;

            // Compare
            if ((sum !== sum_ref) || (cout !== cout_ref)) begin
                $display(" FAIL @ Test %0d | A=%h B=%h Cin=%b", i, a, b, c0);
                $display("   DUT : Sum=%h Cout=%b", sum, cout);
                $display("   REF : Sum=%h Cout=%b\n", sum_ref, cout_ref);
                $fwrite(fd, "%8t | %h | %h |  %b  | %h |  %b   | %h |   %b   | FAIL\n",
                        $time, a, b, c0, sum, cout, sum_ref, cout_ref);
                fails = fails + 1;
            end
            else begin
                $display(" PASS @ Test %0d | A=%h B=%h Cin=%b | Sum=%h Cout=%b",
                          i, a, b, c0, sum, cout);
                $fwrite(fd, "%8t | %h | %h |  %b  | %h |  %b   | %h |   %b   | PASS\n",
                        $time, a, b, c0, sum, cout, sum_ref, cout_ref);
            end
            #5;
        end

        // ------------------------------
        // 3. Final report
        // ------------------------------
        $fwrite(fd, "----------------------------------------------------------\n");
        if (fails == 0) begin
            $display("\n ALL TESTS PASSED SUCCESSFULLY!");
            $fwrite(fd, "RESULT: ALL TESTS PASSED \n");
        end else begin
            $display("\n %0d TEST(S) FAILED!", fails);
            $fwrite(fd, "RESULT: %0d TEST(S) FAILED \n", fails);
        end
        $display("Simulation complete. See cla_log.txt for full log.");
        $fwrite(fd, "===========================================================\n");

        $fclose(fd);
        $finish;
    end
endmodule
