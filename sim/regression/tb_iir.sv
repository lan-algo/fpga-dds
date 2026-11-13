`timescale 1ns/1ps
module tb_iir;
 reg clk=0, rst=1; always #5 clk=~clk;
 reg [31:0] x=0; wire [31:0] y; reg [31:0] previous;
 freq_smooth_iir dut(.clk(clk),.clr(rst),.x_in(x),.y_out(y));
 initial begin
  repeat(2) @(negedge clk); rst=0; x=4000;
  repeat(64) begin @(posedge clk); #1; if(y>4000) $fatal(1,"upward overshoot"); end
  @(negedge clk); x=0; previous=y;
  repeat(64) begin @(posedge clk); #1; if(y>previous) $fatal(1,"falling input wrapped upward: %d -> %d",previous,y); previous=y; end
  if(y!==0) $fatal(1,"filter did not converge to zero: %d",y);
  @(negedge clk); x=1;
  repeat(8) @(negedge clk);
  if(y!==1) $fatal(1,"integer dead band at one");
  x=32'hffffffff; repeat(160) @(negedge clk);
  if(y!==32'hffffffff) $fatal(1,"full-scale convergence failed");
  x=0; previous=y;
  repeat(160) begin @(posedge clk); #1; if(y>previous) $fatal(1,"full-scale decay overflow"); previous=y; end
  if(y!==0) $fatal(1,"full-scale decay stuck");
  $display("PASS iir: rise/fall, integer convergence, full scale"); $finish;
 end
endmodule
