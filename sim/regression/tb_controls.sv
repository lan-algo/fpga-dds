`timescale 1ns/1ps
module tb_controls;
 reg clk=0,rst=1,plus=0,minus=0,en=0;always #5 clk=~clk;
 reg [3:0] range_sel=8;wire [10:0] phase,sweep;wire [31:0] f,sweep_f;
 Frequency_measurement #(.DEBOUNCE_COUNT(3)) control(.clk_10MHz(clk),.rst(rst),.K_switch(8'd1),.S0(plus),.S3(minus),.F(f),.phase_inc(phase));
 sweep_generator #(.DELAY_CNT(3)) scan(.clk_10MHz(clk),.rst(rst),.sweep_en(en),.sweep_rst(1'b0),.SW_SCAN(range_sel),.sweep_phase_inc(sweep),.sweep_F(sweep_f));
 initial begin
  repeat(3) @(negedge clk);rst=0;repeat(2) @(negedge clk);
  if(phase!==8 || f!==39062) $fatal(1,"manual coarse tuning wrong");
  plus=1;repeat(15) @(negedge clk);
  if(phase!==9 || f!==43945) $fatal(1,"debounced press wrong");
  repeat(15) @(negedge clk);if(phase!==9) $fatal(1,"held key repeated");
  plus=0;repeat(10) @(negedge clk);minus=1;repeat(15) @(negedge clk);
  if(phase!==8) $fatal(1,"minus key wrong");
  en=1;repeat(24) begin @(negedge clk);if(sweep>2) $fatal(1,"small sweep escaped range: K=%d sel=%b",sweep,range_sel);if(sweep_f!==((64'd10000000*sweep)>>11)) $fatal(1,"sweep display not aligned");end
  range_sel=2;repeat(2) @(negedge clk);
  if(sweep<21 || sweep>205) $fatal(1,"range switch did not rebase: %d",sweep);
  $display("PASS controls: button debounce/hold, frequency conversion, sweep and range switch");$finish;
 end
endmodule
