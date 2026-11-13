`timescale 1ns/1ps
module tb_top;
 reg clk=0,rst=0; always #5 clk=~clk;
 reg [1:0] mode=0,wave_sel=0;reg sweep_en=0;
 wire [7:0] seg1,seg2;wire [3:0] bit1,bit2,debug_leds;
 wire [13:0] data_out;wire dac_clk,adc_clk,pulse;
 integer j;
 top dut(.clk_100MHz(clk),.rst(rst),.K(8'd1),.SW_SCAN(4'b1000),.DIP(mode),.S0(1'b0),.S3(1'b0),.S1(1'b0),.S4(sweep_en),.seg1(seg1),.seg2(seg2),.bit1(bit1),.bit2(bit2),.dac_data(data_out),.clk_DA(dac_clk),.ad_data(10'd512),.ad_clk(adc_clk),.debug_leds(debug_leds),.pulse_indicator(pulse),.wave_sel(wave_sel));
 initial begin
  #1; rst=1; // Explicit reset edge while the derived clocks are stopped.
  repeat(20) @(negedge clk);rst=0;
  for(j=0;j<4;j=j+1) begin
   mode=j[1:0];wave_sel=j[1:0];
   repeat(500) begin
    @(negedge clk);
    if((^{seg1,seg2,bit1,bit2,data_out,dac_clk,adc_clk,debug_leds,pulse})===1'bx) $fatal(1,"unknown top output: seg=%h/%h bit=%h/%h dac=%h clocks=%b%b debug=%h pulse=%b",seg1,seg2,bit1,bit2,data_out,dac_clk,adc_clk,debug_leds,pulse);
    if(dac_clk!==adc_clk) $fatal(1,"ADC/DAC clocks diverged");
   end
  end
  sweep_en=1;repeat(500) @(negedge clk);
  if((^{seg1,seg2,bit1,bit2,data_out})===1'bx) $fatal(1,"unknown after sweep enable");
  rst=1;repeat(20) @(negedge clk);rst=0;repeat(500) @(negedge clk);
  if((^{seg1,seg2,data_out})===1'bx) $fatal(1,"unknown after reset");
  $display("PASS top: reset, four modes, clock outputs, sweep enable without unknown outputs");$finish;
 end
endmodule
