`timescale 1ns/1ps
module tb_gate;
 reg clk=0,rst=1,sig=0; always #5 clk=~clk;
 wire [31:0] f; integer i;
 gate_counter #(.CLK_FREQ(1000),.GATE_TIME(10)) dut(.clk(clk),.rst(rst),.signal_in(sig),.frequency(f));
 initial begin
  repeat(2) @(negedge clk); rst=0;
  for(i=1;i<=10;i=i+1) begin
   sig=(i==2 || i==5 || i==10);
   @(posedge clk); #1;
   if(i<10 && f!==0) $fatal(1,"window ended early");
   if(i==10 && f!==300) $fatal(1,"closing sample/window size wrong: %d",f);
   @(negedge clk);
  end
  sig=0; repeat(10) @(negedge clk);
  if(f!==0) $fatal(1,"empty window retained old frequency");
  rst=1; sig=1; repeat(3) @(negedge clk); sig=0; rst=0;
  repeat(10) @(negedge clk);
  if(f!==0) $fatal(1,"reset introduced phantom edge");
  $display("PASS gate: exact window, closing edge, empty window, reset");$finish;
 end
endmodule
