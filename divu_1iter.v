module divu_1iter (
    input  wire [32:0] rem_in,       // remainder input (33 bits)
    input  wire        dividend_bit, // single bit from dividend (MSB -> LSB)
    input  wire [31:0] divisor,      // divisor (32 bits)
    output wire [32:0] rem_out,      // remainder output (33 bits)
    output wire        q_bit         // quotient bit produced at this iteration
);
    // shift rem left 1 and bring in dividend_bit as LSB
    wire [32:0] rem_shift;
    assign rem_shift = { rem_in[31:0], dividend_bit }; // rem_in[32] is dropped into rem_shift[32] via shift

    // extend divisor to 33 bits for comparison/subtraction
    wire [32:0] divisor_ext;
    assign divisor_ext = {1'b0, divisor};

    // compare and subtract (all combinational)
    wire ge = (rem_shift >= divisor_ext);
    assign q_bit = ge ? 1'b1 : 1'b0;
    assign rem_out = ge ? (rem_shift - divisor_ext) : rem_shift;
endmodule
