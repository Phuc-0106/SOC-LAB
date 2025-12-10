`timescale 1ns / 1ps

module display_controller(
    input  wire clk,
    input  wire tick,
    input  wire rst,
    input  wire mode,
    output reg  [3:0] posC, 
    output reg  [3:0] posE
);
    // ===== PARAMETERS =====
    reg dir; // 1 = right, 0 = left

    // ===== INITIALIZATION =====
    initial begin
        posC = 4'b0001;  // C starts at leftmost position
        posE = 4'b0010;  // E starts at second position  
        dir  = 1'b1;     // Start moving right
    end

    // ===== MOVEMENT LOGIC =====
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            posC <= 4'b0001;
            posE <= 4'b0010;
            dir  <= 1'b1;
        end
        else if (tick) begin
            case (mode)
                1'b0: begin
                    // Mode 0: Continuous rotation
                    posC <= {posC[2:0], posC[3]};
                    posE <= {posE[2:0], posE[3]};
                end

                1'b1: begin
                    // Mode 1: Bounce between edges
                    if (dir) begin
                        // Moving right
                        if (posE == 4'b1000) begin
                            // Hit right edge, reverse direction
                            dir  <= 1'b0;
                        end else begin
                            // Continue moving right
                            posC <= posC << 1;
                            posE <= posE << 1;
                        end
                    end else begin
                        // Moving left
                        if (posC == 4'b0001) begin
                            // Hit left edge, reverse direction
                            dir  <= 1'b1;
                        end else begin
                            // Continue moving left
                            posC <= posC >> 1;
                            posE <= posE >> 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule