`timescale 1ns/1ps
module tb_duty;
 reg clk=0,rst_n=0,sig=0; always #5 clk=~clk;
 wire [15:0] duty; integer i;
 duty_cycle_meter dut(.clk(clk),.rst_n(rst_n),.catin(sig),.PonTemp(duty));
 task pulse(input integer hi,input integer lo); begin sig=1;repeat(hi) @(negedge clk);sig=0;repeat(lo) @(negedge clk);end endtask
 initial begin
  repeat(3) @(negedge clk);rst_n=1;repeat(17) @(negedge clk);
  repeat(8) pulse(5,5);
  if(duty!==50) $fatal(1,"50 percent measured as %d",duty);
  repeat(8) pulse(2,8);
  if(duty!==20) $fatal(1,"20 percent measured as %d",duty);
  repeat(8) pulse(8,2);
  if(duty!==80) $fatal(1,"80 percent measured as %d",duty);
  repeat(8) pulse(1,99);
  if(duty!==1) $fatal(1,"1 percent measured as %d",duty);
  rst_n=0;repeat(3) @(negedge clk);
  if(duty!==0) $fatal(1,"reset output not zero");
  $display("PASS duty: 50/20/80/1 percent, startup, reset");$finish;
 end
endmodule
