`timescale 1ns / 1ps

module DividerUnsignedPipelined #(
    parameter BIT_W = 32
)(
    input                   clk,
    input                   rst,       
    input                   start,      
    input      [BIT_W-1:0]  dividend,
    input      [BIT_W-1:0]  divisor,
    output reg [BIT_W-1:0]  quotient,
    output reg [BIT_W-1:0]  remainder,
    output reg              done
);


    reg [BIT_W-1:0]  dividend_pipe [0:7];
    reg [BIT_W-1:0]  divisor_pipe  [0:7];
    reg [BIT_W-1:0]  quotient_pipe [0:7];
    reg [BIT_W-1:0]  remainder_pipe[0:7];
    reg [5:0]        bitpos_pipe   [0:7];   
    reg [7:0]        valid_pipe;          

    integer i;

    function [2*BIT_W+6-1:0] do4;
        input [BIT_W-1:0] rem_in;
        input [BIT_W-1:0] quo_in;
        input [BIT_W-1:0] dividend_in;
        input [BIT_W-1:0] divisor_in;
        input [5:0]       bitpos_in;

        reg [BIT_W-1:0] rem;
        reg [BIT_W-1:0] quo;
        reg [5:0]       idx;
        integer         j;
    begin
        rem = rem_in;
        quo = quo_in;
        idx = bitpos_in;

        for (j = 0; j < 4; j = j + 1) begin
            rem = {rem[BIT_W-2:0], dividend_in[idx]};

            if (rem >= divisor_in) begin
                rem = rem - divisor_in;           
                quo = {quo[BIT_W-2:0], 1'b1};
            end else begin
                quo = {quo[BIT_W-2:0], 1'b0};
            end

            if (idx != 0)
                idx = idx - 1;
        end

        do4 = {rem, quo, idx};
    end
    endfunction
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Clear pipeline
            for (i = 0; i < 8; i = i + 1) begin
                dividend_pipe[i]  <= {BIT_W{1'b0}};
                divisor_pipe[i]   <= {BIT_W{1'b0}};
                quotient_pipe[i]  <= {BIT_W{1'b0}};
                remainder_pipe[i] <= {BIT_W{1'b0}};
                bitpos_pipe[i]    <= 6'd0;
            end
            valid_pipe <= 8'b0;
            quotient   <= {BIT_W{1'b0}};
            remainder  <= {BIT_W{1'b0}};
            done       <= 1'b0;
        end else begin
            if (start) begin
                dividend_pipe[0] <= dividend;
                divisor_pipe[0]  <= divisor;

                {remainder_pipe[0], quotient_pipe[0], bitpos_pipe[0]} <=
                    do4({BIT_W{1'b0}}, {BIT_W{1'b0}},
                        dividend, divisor,
                        BIT_W[5:0] - 1'b1);  

                valid_pipe[0] <= 1'b1;
            end else begin
                dividend_pipe[0]  <= {BIT_W{1'b0}};
                divisor_pipe[0]   <= {BIT_W{1'b0}};
                quotient_pipe[0]  <= {BIT_W{1'b0}};
                remainder_pipe[0] <= {BIT_W{1'b0}};
                bitpos_pipe[0]    <= 6'd0;
                valid_pipe[0]     <= 1'b0;
            end
            for (i = 1; i < 8; i = i + 1) begin
                if (valid_pipe[i-1]) begin
                    dividend_pipe[i] <= dividend_pipe[i-1];
                    divisor_pipe[i]  <= divisor_pipe[i-1];

                    {remainder_pipe[i], quotient_pipe[i], bitpos_pipe[i]} <=
                        do4(remainder_pipe[i-1], quotient_pipe[i-1],
                            dividend_pipe[i-1],  divisor_pipe[i-1],
                            bitpos_pipe[i-1]);

                    valid_pipe[i] <= 1'b1;
                end else begin
                    dividend_pipe[i]  <= {BIT_W{1'b0}};
                    divisor_pipe[i]   <= {BIT_W{1'b0}};
                    quotient_pipe[i]  <= {BIT_W{1'b0}};
                    remainder_pipe[i] <= {BIT_W{1'b0}};
                    bitpos_pipe[i]    <= 6'd0;
                    valid_pipe[i]     <= 1'b0;
                end
            end
            done <= valid_pipe[7];

            if (valid_pipe[7]) begin
                quotient  <= quotient_pipe[7];
                remainder <= remainder_pipe[7];
            end
        end
    end

endmodule
