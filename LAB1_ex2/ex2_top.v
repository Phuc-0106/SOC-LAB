`timescale 1ns / 1ps

module Lab1_ex2(
    input wire clk,
    input wire rst,
    input wire [1:0] sw_mode,
    input wire btn_inc,
    input wire btn_dec,
    input wire btn_sel,
    output reg [3:0] led1_out,
    output reg [3:0] led2_out,
    output reg [3:0] led3_out,
    output reg [3:0] led4_out
);

    // ===== PARAMETERS =====
    localparam DEFAULT_VALUE = 27'b0;
    localparam MAX_COUNT = 100_000_000; // 1 second at 100MHz
    localparam MIN_COUNT = 10_000_000;  // 0.1 second minimum
    localparam MAX_BTN_COUNT = 1000;    // Maximum button acceleration
    
    // ===== INTERNAL SIGNALS =====
    wire tick;
    reg tick_reg;
    wire [3:0] posC, posE;
    reg [26:0] counter, counter_new;
    reg [26:0] btn_counter_inc, btn_counter_dec;
    
    // Button edge detection
    reg btn_inc_prev, btn_dec_prev, btn_sel_prev;
    wire btn_inc_pulse, btn_dec_pulse, btn_sel_pulse;
    
    // ===== BUTTON EDGE DETECTION =====
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_inc_prev <= 0;
            btn_dec_prev <= 0;
            btn_sel_prev <= 0;
        end else begin
            btn_inc_prev <= btn_inc;
            btn_dec_prev <= btn_dec;
            btn_sel_prev <= btn_sel;
        end
    end
    
    assign btn_inc_pulse = btn_inc & ~btn_inc_prev;
    assign btn_dec_pulse = btn_dec & ~btn_dec_prev;
    assign btn_sel_pulse = btn_sel & ~btn_sel_prev;
    
    // ===== MAIN COUNTER LOGIC =====
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_counter_inc <= DEFAULT_VALUE;
            btn_counter_dec <= DEFAULT_VALUE;
            counter <= MAX_COUNT;
            counter_new <= MAX_COUNT;
            tick_reg <= 0;
        end else begin
            // Reset button counters periodically
            if (btn_counter_inc > 0 && !btn_inc) 
                btn_counter_inc <= DEFAULT_VALUE;
            if (btn_counter_dec > 0 && !btn_dec)
                btn_counter_dec <= DEFAULT_VALUE;
            
            // Button acceleration
            if (btn_inc_pulse)
                btn_counter_inc <= (btn_counter_inc < MAX_BTN_COUNT) ? btn_counter_inc + 1 : MAX_BTN_COUNT;
            if (btn_dec_pulse)
                btn_counter_dec <= (btn_counter_dec < MAX_BTN_COUNT) ? btn_counter_dec + 1 : MAX_BTN_COUNT;
            
            // Speed adjustment in configuration mode
            if (sw_mode[1]) begin
                if (btn_sel_pulse) begin
                    if (btn_counter_inc > 0) 
                        counter_new <= (counter_new > MIN_COUNT + btn_counter_inc) ? 
                                      (counter_new - btn_counter_inc) : MIN_COUNT;
                    else if (btn_counter_dec > 0)
                        counter_new <= (counter_new < MAX_COUNT - btn_counter_dec) ? 
                                      (counter_new + btn_counter_dec) : MAX_COUNT;
                end
            end

            // Main timer counter
            if (counter == 0) begin
                tick_reg <= 1;
                counter <= counter_new;
            end else begin
                tick_reg <= 0;
                counter <= counter - 1;
            end
        end
    end

    assign tick = tick_reg;
    
    // ===== DISPLAY CONTROLLER INSTANCE =====
    display_controller control(
        .clk(clk),          
        .tick(tick),
        .rst(rst),
        .mode(sw_mode[0]),
        .posC(posC),
        .posE(posE)
    );
    
    // ===== LED OUTPUT DECODING =====

    
    always @(*) begin
        // Default all LEDs to off
        led1_out = 4'h0;  // Blank
        led2_out = 4'h0;  // Blank
        led3_out = 4'h0;  // Blank
        led4_out = 4'h0;  // Blank
        
        // Hi?n th? 'C' (s? 0) ? c?c v? tr? ???c ch? ??nh b?i posC
        if (posC[0]) led1_out = 4'd2;  // Hi?n th? s? 2 cho 'C'
        if (posC[1]) led2_out = 4'h2;
        if (posC[2]) led3_out = 4'h2;
        if (posC[3]) led4_out = 4'h2;

        // Hi?n th? 'E' (s? 8) ? c?c v? tr? ???c ch? ??nh b?i posE
        if (posE[0]) led1_out = 4'd5;  // Hi?n th? s? 5 cho 'E'
        if (posE[1]) led2_out = 4'd5;
        if (posE[2]) led3_out = 4'd5;
        if (posE[3]) led4_out = 4'd5;
    end

endmodule