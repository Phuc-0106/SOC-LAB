`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Traffic light with auto/manual mode - Improved version
//////////////////////////////////////////////////////////////////////////////////

module traffic_fsm(
    input wire rst,
    input wire clk,
    input wire tick,
    input wire sw_mode,
    input wire btn_sel,
    input wire btn_inc,
    input wire btn_dec,
    output reg [3:0] counter,
    output reg [2:0] lightA,
    output reg [2:0] lightB,
    output reg [3:0] seg_7A,
    output reg [3:0] seg_7B
);

    // ===== PARAMETERS AND DEFINITIONS =====
    // Time settings
    reg [3:0] green_time = 4'd3;
    reg [3:0] yellow_time = 4'd2;
    reg [3:0] red_time;
    
    // FSM states
    localparam [2:0] 
        G1 = 3'd0,  // Green light A, Red light B
        Y1 = 3'd1,  // Yellow light A, Red light B  
        G2 = 3'd2,  // Red light A, Green light B
        Y2 = 3'd3,  // Red light A, Yellow light B
        M1 = 3'd4,  // Manual mode - adjust green time
        M2 = 3'd5;  // Manual mode - adjust yellow time

    // Light encoding
    localparam [2:0] 
        RED    = 3'b100,
        YELLOW = 3'b010,
        GREEN  = 3'b001,
        OFF    = 3'b000;

    // ===== INTERNAL SIGNALS =====
    reg [2:0] state = G1;
    reg [1:0] sel_counter = 0;
    reg btn_inc_prev, btn_dec_prev;
    wire btn_inc_pulse, btn_dec_pulse;

    // ===== BUTTON EDGE DETECTION =====
    always @(posedge clk) begin
        btn_inc_prev <= btn_inc;
        btn_dec_prev <= btn_dec;
    end 

    assign btn_inc_pulse = btn_inc & ~btn_inc_prev; 
    assign btn_dec_pulse = btn_dec & ~btn_dec_prev;

    // ===== TIME SETTINGS LOGIC =====
    always @(posedge clk) begin
        red_time <= green_time + yellow_time;  // Calculate red time
        
        if (sw_mode) begin  // Manual mode - adjust timing
            case(state)
                M1: begin  // Adjust green time
                    if (btn_inc_pulse && green_time < 9)
                        green_time <= green_time + 1;
                    else if (btn_dec_pulse && green_time > 1)
                        green_time <= green_time - 1;
                end
                M2: begin  // Adjust yellow time
                    if (btn_inc_pulse && yellow_time < 9)
                        yellow_time <= yellow_time + 1;
                    else if (btn_dec_pulse && yellow_time > 1)
                        yellow_time <= yellow_time - 1;
                end
            endcase
        end
    end

    // ===== FSM STATE TRANSITION =====
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= G1;
            counter <= 0;
            sel_counter <= 0;
        end
        else begin
            if (!sw_mode) begin
                // ===== AUTO MODE =====
                sel_counter <= 0;  // Reset selection counter
                
                if (state == M1 || state == M2) begin
                    state <= G1;  // Return to auto mode from manual
                end
                
                if (tick) begin
                    counter <= counter + 1;
                    case(state)
                        G1: if (counter >= green_time) begin 
                                counter <= 0; 
                                state <= Y1; 
                            end
                        Y1: if (counter >= yellow_time) begin 
                                counter <= 0; 
                                state <= G2; 
                            end
                        G2: if (counter >= green_time) begin 
                                counter <= 0; 
                                state <= Y2; 
                            end
                        Y2: if (counter >= yellow_time) begin 
                                counter <= 0; 
                                state <= G1; 
                            end
                    endcase
                end
            end
            else begin
                // ===== MANUAL MODE =====
                counter <= 0;  // Reset counter in manual mode
                
                if (btn_sel) begin
                    sel_counter <= sel_counter + 1;
                end
                
                case(sel_counter)
                    2'b00: state <= M1;  // Green time adjustment
                    2'b01: state <= M2;  // Yellow time adjustment
                    default: sel_counter <= 2'b00;  // Wrap around
                endcase
            end
        end
    end

    // ===== OUTPUT LOGIC =====
    always @(*) begin
        case(state)
            G1: begin  // Green A, Red B
                lightA = GREEN;
                lightB = RED;
                seg_7A = red_time - counter;
                seg_7B = green_time - counter;
            end
            Y1: begin  // Yellow A, Red B
                lightA = YELLOW;
                lightB = RED;
                seg_7A = red_time - counter;
                seg_7B = yellow_time - counter;
            end
            G2: begin  // Red A, Green B
                lightA = RED;
                lightB = GREEN;
                seg_7A = green_time - counter;
                seg_7B = red_time - counter;
            end
            Y2: begin  // Red A, Yellow B
                lightA = RED;
                lightB = YELLOW;
                seg_7A = yellow_time - counter;
                seg_7B = red_time - counter;
            end
            M1: begin  // Manual green time adjustment
                lightA = YELLOW;
                lightB = OFF;
                seg_7A = green_time;
                seg_7B = 4'd0;
            end
            M2: begin  // Manual yellow time adjustment
                lightA = GREEN;
                lightB = OFF;
                seg_7A = yellow_time;
                seg_7B = 4'd0;
            end
            default: begin
                lightA = OFF;
                lightB = OFF;
                seg_7A = 0;
                seg_7B = 0;
            end
        endcase
    end

endmodule