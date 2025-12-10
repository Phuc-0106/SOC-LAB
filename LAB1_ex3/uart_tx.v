`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire send,
    output reg tx,
    output wire busy
);
    
    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    localparam IDLE = 0;
    localparam START = 1;
    localparam DATA = 2;
    localparam STOP = 3;
    
    reg [1:0] state = IDLE;
    reg [15:0] counter = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] shift_reg = 0;
    
    assign busy = (state != IDLE);
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx <= 1'b1;
            counter <= 0;
            bit_index <= 0;
            shift_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (send) begin
                        state <= START;
                        shift_reg <= data_in;
                        counter <= 0;
                    end
                end
                
                START: begin
                    tx <= 1'b0;
                    if (counter >= BIT_PERIOD - 1) begin
                        state <= DATA;
                        counter <= 0;
                        bit_index <= 0;
                    end else begin
                        counter <= counter + 1;
                    end
                end
                
                DATA: begin
                    tx <= shift_reg[0];
                    if (counter >= BIT_PERIOD - 1) begin
                        counter <= 0;
                        shift_reg <= {1'b0, shift_reg[7:1]};
                        if (bit_index >= 7) begin
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else begin
                        counter <= counter + 1;
                    end
                end
                
                STOP: begin
                    tx <= 1'b1;
                    if (counter >= BIT_PERIOD - 1) begin
                        state <= IDLE;
                        counter <= 0;
                    end else begin
                        counter <= counter + 1;
                    end
                end
            endcase
        end
    end

endmodule