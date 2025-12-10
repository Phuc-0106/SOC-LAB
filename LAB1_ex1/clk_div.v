module timer(
    input wire clk,
    input wire rst,
    output reg tick = 0
    );
    

localparam integer COUNT_MAX = 100;  // Reduced for simulation (was 100_000_000)
reg [31:0] counter = 0;  

always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 0;
        tick <= 0;
    end
    else if (counter == COUNT_MAX - 1)begin
        tick <= 1;
        counter <= 0;
    end
    else begin
        counter <= counter + 1;
        tick <= 0;
    end
end
endmodule