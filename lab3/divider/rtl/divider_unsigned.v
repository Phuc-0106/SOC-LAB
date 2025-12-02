module divider_unsigned(
    input  [31:0] dividend,
    input  [31:0] divisor,
    output [31:0] quotient,
    output [31:0] remainder
);

    wire [31:0] remainder_out_w [0:32];
    wire [31:0] quotient_out_w;
    assign remainder_out_w[0] = 0;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_divu
            divu_1iter iter (
                .dividend_bit (dividend[31 - i]),        
                .divisor_in   (divisor),
                .remainder_in (remainder_out_w[i]),
                .remainder_out(remainder_out_w[i + 1]),
                .quotient_bit (quotient_out_w[31 - i])
            );
        end
    endgenerate

    assign quotient  = quotient_out_w;
    assign remainder = remainder_out_w[32];
endmodule
