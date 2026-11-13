`timescale 1ns/1ps
module tb_period;
 reg clk=0,rst=1,rise=0; always #5 clk=~clk;
 wire [31:0] f; integer i;
 period_counter_avg #(.F_REF_HZ(1000),.N_CYCLES(4)) dut(.clk_ref(clk),.clr(rst),.rise_p(rise),.freq_hz(f));
 task edge_pulse; begin rise=1;@(posedge clk);#1;@(negedge clk);rise=0;end endtask
 task next_edge; begin repeat(9) @(negedge clk);edge_pulse;end endtask
 initial begin
  repeat(2) @(negedge clk);rst=0;repeat(37) @(negedge clk);
  edge_pulse;
  for(i=0;i<3;i=i+1) next_edge;
  if(f!==0) $fatal(1,"first partial interval counted: %d",f);
  next_edge;
  if(f!==100) $fatal(1,"four complete periods should give 100: %d",f);
  repeat(4) next_edge;
  if(f!==100) $fatal(1,"successive window incorrect");
  repeat(2100) @(negedge clk);
  if(f!==0) $fatal(1,"lost signal retained stale period result");
  $display("PASS period: delayed first edge, complete intervals, repeated window, timeout");$finish;
 end
endmodule
