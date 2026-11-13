`timescale 1ns/1ps
module tb_display;
 reg clk=0,rst=1;always #5 clk=~clk;
 reg [1:0] mode=2;reg [31:0] f=0,adc=0;reg [15:0] duty=0;
 wire [7:0] s1,s2;wire [3:0] b1,b2;
 LED dut(.clk_1kHz(clk),.rst(rst),.DIP(mode),.F(f),.adc_frequency(adc),.duty_cycle(duty),.seg1(s1),.seg2(s2),.bit1(b1),.bit2(b2));
 function [7:0] digit(input integer n);
  case(n) 0:digit=8'h3f;1:digit=8'h06;2:digit=8'h5b;3:digit=8'h4f;4:digit=8'h66;5:digit=8'h6d;6:digit=8'h7d;7:digit=8'h07;8:digit=8'h7f;9:digit=8'h6f;default:digit=0;endcase
 endfunction
 task check_number(input [31:0] number);
  integer i;reg [31:0] remaining;begin
   rst=1;@(negedge clk);rst=0;remaining=number;
   for(i=0;i<8;i=i+1) begin
    #1;
    if(i<4) begin if((s1&8'h7f)!==digit(remaining%10)) $fatal(1,"low display digit %d incorrect",i); end
    else begin if((s2&8'h7f)!==digit(remaining%10)) $fatal(1,"high display digit %d incorrect",i); end
    if ((^{b2,b1}) === 1'bx || {b2,b1} == 0 || (({b2,b1} & ({b2,b1}-8'd1)) != 0)) $fatal(1,"scan not one hot: %b %b",b2,b1);
    remaining=remaining/10;@(negedge clk);
   end
  end
 endtask
 initial begin
  check_number(0);adc=32'd12345678;check_number(adc);
  mode=1;f=32'd39062;check_number(f);
  mode=3;duty=16'd50;check_number(50);
  mode=1;f=32'hffffffff;check_number(99999999);
  $display("PASS display: zero/no +3, eight digits, duty, overflow saturation");$finish;
 end
endmodule
