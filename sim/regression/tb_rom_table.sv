`timescale 1ns/1ps
module tb_rom_table;
 reg clk=0; always #5 clk=~clk;
 reg [7:0] addr=0;wire [7:0] data;
 reg [7:0] expected[0:255];reg [7:0] held;integer i;
 sin_rom dut(.clka(clk),.addra(addr),.douta(data));
 initial begin
  $readmemh("sin_wave_256x8.mem",expected);
  repeat(2) @(negedge clk);
  for(i=0;i<256;i=i+1) begin
   held=data;addr=i[7:0];#1;
   if(data!==held) $fatal(1,"ROM changed without clock at %d",i);
   @(posedge clk);#1;
   if(data!==expected[i]) $fatal(1,"ROM sample mismatch at %d: %d expected %d",i,data,expected[i]);
   @(negedge clk);
  end
  $display("PASS ROM: all 256 COE-derived samples, synchronous read and hold");$finish;
 end
endmodule
