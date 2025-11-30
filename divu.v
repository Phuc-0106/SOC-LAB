`include "divu_1iter.v"
module divu (
    input  wire [31:0] dividend,
    input  wire [31:0] divisor,
    output wire [31:0] quotient,
    output wire [31:0] remainder
);
    // 33-bit remainder wires: stage 0 is initial (0), stage 32 is final
    wire [32:0] rem_wire [0:32];
    assign rem_wire[0] = 33'b0;

    // quotient bits
    wire q_bits [31:0];

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : DIV_STAGES
            // dividend bit used at this stage: start from MSB
            wire dbit = dividend[31 - i];

            divu_1iter iter (
                .rem_in(rem_wire[i]),
                .dividend_bit(dbit),
                .divisor(divisor),
                .rem_out(rem_wire[i+1]),
                .q_bit(q_bits[31 - i]) // produce MSB first
            );
        end
    endgenerate

    // assign quotient vector from q_bits
    genvar j;
    generate
        for (j = 0; j < 32; j = j + 1) begin : ASSIGN_Q
            assign quotient[j] = q_bits[j];
        end
    endgenerate

    // final remainder (lower 32 bits of 33-bit rem)
    assign remainder = rem_wire[32][31:0];
endmodule