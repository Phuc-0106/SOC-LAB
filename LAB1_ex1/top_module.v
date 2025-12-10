module top_module(
     input wire rst,
     input wire clk,
     input wire sw_mode,
     input wire btn_sel,
     input wire btn_inc,
     input wire btn_dec,
     
     output wire [2:0] lightA,
     output wire  [2:0] lightB,
     output wire [3:0] seg_7A,
     output wire [3:0] seg_7B
      );
     wire tick;
     wire [3:0] counter;
     wire [3:0] green_time, yellow_time ;
     
    timer timer
    (
        .clk(clk),
        .rst(rst),
        .tick(tick)
    );
    
   
    traffic_fsm  fsm
    (
        .clk(clk),
        .rst(rst),
        .tick(tick),
        .sw_mode(sw_mode),
        .btn_sel(btn_sel),
        .btn_inc(btn_inc),
        .btn_dec(btn_dec),
        .lightA(lightA),
        .lightB(lightB),
        .counter(counter),
        .seg_7A(seg_7A),
        .seg_7B(seg_7B)
     );
  
endmodule