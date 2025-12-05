module divu_1iter(
    input        dividend_bit,      
    input  [31:0] divisor_in,
    input  [31:0] remainder_in,
    output [31:0] remainder_out,
    output        quotient_bit
    );
    
    reg [31:0] remainder_tmp;
    reg quotient_tmp;

    always @(*) begin
        remainder_tmp = (remainder_in << 1) | dividend_bit; 
        if (remainder_tmp < divisor_in) begin
            quotient_tmp = 1'b0;
        end else begin
            quotient_tmp = 1'b1;
            remainder_tmp = remainder_tmp - divisor_in;
        end
    end

    assign remainder_out = remainder_tmp;
    assign quotient_bit  = quotient_tmp;
endmodule