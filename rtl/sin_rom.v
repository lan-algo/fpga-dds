`timescale 1ns / 1ps
// 波形采样值来自 data/sin_wave_256x8.coe；使用 build_rom.py 转换为 MEM。
// 256×8 ROM，一拍读出。静态数据由 check_project.py 校验。
module sin_rom(input wire clka, input wire [7:0] addra, output reg [7:0] douta);
    reg [7:0] sin_table [0:255];
    initial $readmemh("sin_wave_256x8.mem", sin_table);
    always @(posedge clka) douta <= sin_table[addra];
endmodule
