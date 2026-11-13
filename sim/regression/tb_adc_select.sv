`timescale 1ns/1ps
module tb_adc_select;
 reg clk=0,rst=1;always #5 clk=~clk;
 wire [31:0] raw_f,smooth_f;wire [3:0] debug_s;wire pulse,schmitt;
 adc_frequency_meter dut(.clk_10MHz(clk),.rst(rst),.ad_data(10'd512),.frequency_raw(raw_f),.frequency_smooth(smooth_f),.debug_state(debug_s),.pulse_led(pulse),.schmitt_out(schmitt));
 initial begin
  repeat(2) @(negedge clk);rst=0;
  // Isolate the selection boundary: fast measurement arrived, slow measurement not ready.
  force dut.freq_period_fast=32'd20;force dut.freq_period_slow=32'd0;force dut.freq_gate=32'd0;
  repeat(4) @(negedge clk);
  if(raw_f!==20) $fatal(1,"startup blocked on slow measurement: %d",raw_f);
  force dut.freq_gate=32'd2000;repeat(4) @(negedge clk);
  if(raw_f!==2000) $fatal(1,"high frequency selection wrong");
  force dut.freq_gate=32'd0;force dut.freq_period_fast=32'd0;repeat(4) @(negedge clk);
  if(raw_f!==0) $fatal(1,"invalid measurements retained nonzero output");
  $display("PASS selection: fast startup, gate priority, cleared inputs");$finish;
 end
endmodule
