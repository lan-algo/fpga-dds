`timescale 1ns/1ps
module tb_dds;
 reg clk=0,rst=1;always #50 clk=~clk;
 reg [10:0] k=8;wire [7:0] sn,sq,tr,sw;wire [13:0] dac;
 DDS a(.clk_10MHz(clk),.rst(rst),.K(k),.wave_sel(2'd0),.wave_data(sn));
 DDS b(.clk_10MHz(clk),.rst(rst),.K(k),.wave_sel(2'd1),.wave_data(sq));
 DDS c(.clk_10MHz(clk),.rst(rst),.K(k),.wave_sel(2'd2),.wave_data(tr));
 DDS d(.clk_10MHz(clk),.rst(rst),.K(k),.wave_sel(2'd3),.wave_data(sw));
 dac_driver e(.rom_data(sn),.dac_data(dac));
 integer i,rises,wraps,min_sn,max_sn,min_tr,max_tr;reg [7:0] prev_sq,prev_sw;
 task count_periods(input integer expected);
 begin
  repeat(16) @(negedge clk);prev_sq=sq;prev_sw=sw;rises=0;wraps=0;min_sn=255;max_sn=0;min_tr=255;max_tr=0;
  for(i=0;i<1024;i=i+1) begin
   @(negedge clk);
   if((^{sn,sq,tr,sw,dac})===1'bx) $fatal(1,"unknown waveform after warmup");
   if(sq>prev_sq) rises=rises+1;if(sw<prev_sw) wraps=wraps+1;
   prev_sq=sq;prev_sw=sw;if(sn<min_sn) min_sn=sn;if(sn>max_sn) max_sn=sn;if(tr<min_tr) min_tr=tr;if(tr>max_tr) max_tr=tr;
   if(dac[13:6]!==sn || dac[5:0]!==0) $fatal(1,"DAC width alignment wrong");
  end
  if(rises!=expected || wraps!=expected) $fatal(1,"wrong period count: %d %d",rises,wraps);
  if(min_sn!=1 || max_sn!=255 || min_tr!=0 || max_tr!=255) $fatal(1,"wrong wave amplitudes");
 end endtask
 initial begin
  repeat(3) @(negedge clk);if(sn!==0 || sq!==0 || tr!==0 || sw!==0) $fatal(1,"reset output wrong");rst=0;
  count_periods(4);k=16;count_periods(8);
  $display("PASS DDS: reset, four waveforms, K8/K16 period count and DAC interface");$finish;
 end
endmodule
