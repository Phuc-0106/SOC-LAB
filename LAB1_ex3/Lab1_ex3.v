`timescale 1ns / 1ps

module Lab1_ex3(
    input wire clk,
    input wire rst,
    input wire [3:0] btn,
    output reg [3:0] led,
    output wire uart_tx
);
    
    reg tick;
    localparam [3:0] DEFAULT_VALUE = 4'b0011;
    localparam [1:0] RESET = 2'b00;
    localparam [1:0] BTN1 = 2'b01;
    localparam [1:0] BTN2 = 2'b10;
    localparam [1:0] BTN3 = 2'b11;
    
    reg [26:0] counter;
    localparam [26:0] MAX_HZ = 100; // Gi?m xu?ng cho simulation, dùng 125_000_000 cho FPGA th?c
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            tick <= 0;
        end
        else if (counter >= MAX_HZ - 1) begin
            counter <= 0;
            tick <= 1;
        end
        else begin
            counter <= counter + 1;
            tick <= 0;
        end
    end
    
    reg [1:0] state = RESET;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= RESET;
        end
        else begin
            if (btn[0]) state <= BTN1;
            else if (btn[1]) state <= BTN2;
            else if (btn[2]) state <= BTN3;
            else state <= state;
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) led <= DEFAULT_VALUE;
        else begin
            if (tick) begin
                case(state)
                    RESET: led <= DEFAULT_VALUE;
                    BTN1: led <= {led[2:0], led[3]};
                    BTN2: led <= {led[0], led[3:1]};
                    BTN3: led <= led;
                endcase
            end
        end
    end
    
    // ===== UART TX Instance =====
    reg [7:0] tx_data;
    reg tx_send;
    wire tx_busy;
    reg tx_send_prev;

    uart_tx #(
        .CLK_FREQ(125_000_000),
        .BAUD_RATE(115200)
    ) uart_tx_inst (
        .clk(clk),
        .rst(rst),
        .data_in(tx_data),
        .send(tx_send),
        .tx(uart_tx),
        .busy(tx_busy)
    );

    // ===== G?i d? li?u LED ra UART =====
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_send <= 0;
            tx_data <= 0;
            tx_send_prev <= 0;
        end else begin
            // Ch? g?i khi c? thay ??i tr?ng th?i LED v? UART kh?ng busy
            if (tick && !tx_busy && !tx_send_prev) begin
                // G?i m? ASCII c?a s? (LED[3:0] + 48 ?? hi?n th? 0-9)
                // Th?m 48 ?? chuy?n th?nh k? t? s? '0'-'9'
                tx_data <= (led < 10) ? (led + 48) : (led - 10 + 65);
                tx_send <= 1;
                tx_send_prev <= 1;
            end else begin
                tx_send <= 0;
                if (!tx_busy) begin
                    tx_send_prev <= 0;
                end
            end
        end
    end

endmodule