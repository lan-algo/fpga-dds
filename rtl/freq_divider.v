`timescale 1ns / 1ps

// 频率分频器模块，将一个 100MHz 的输入时钟（clk_100MHz）分频，
// 产生两个输出时钟：10MHz（clk_10MHz）和 1kHz（clk_1kHz）。
module freq_divider(
    input clk_100MHz,  // 输入时钟，频率为 100MHz
    input rst,         // 复位信号，高电平有效（同步复位）
    output reg clk_10MHz, // 输出时钟，频率为 10MHz
    output reg clk_1kHz  // 输出时钟，频率为 1kHz
);

    // 定义两个寄存器用于计数
    reg [3:0] cnt10 = 4'd0;   // 用于 10MHz 分频的计数器（4位，范围0-15）
    reg [16:0] cnt1k = 17'd0; // 用于 1kHz 分频的计数器（17位，范围0-131071）

    // ------------------- 10MHz 分频逻辑 -------------------
    // 100MHz 时钟周期为 10ns。要得到 10MHz 时钟（周期 100ns），
    // 需要将输入时钟分频 10 倍。由于是通过翻转输出实现，
    // 因此计数器只需计数到 (10/2 - 1) = 4。
    always @(posedge clk_100MHz or posedge rst) begin
        if(rst) begin
            // 复位时，计数器清零，输出时钟置为低电平
            cnt10 <= 4'd0;
            clk_10MHz <= 1'b0;
        end else begin
            // 当计数器计数到 4 时
            if(cnt10 == 4'd4) begin
                cnt10 <= 4'd0;      // 计数器清零，准备下一个周期
                clk_10MHz <= ~clk_10MHz; // 翻转输出时钟的电平
            end else begin
                // 否则，计数器加 1
                cnt10 <= cnt10 + 1'b1;
            end
        end
    end

    // ------------------- 1kHz 分频逻辑 -------------------
    // 100MHz 时钟周期为 10ns。要得到 1kHz 时钟（周期 1,000,000ns），
    // 需要将输入时钟分频 100,000 倍。由于是通过翻转输出实现，
    // 因此计数器只需计数到 (100,000/2 - 1) = 49999。
    always @(posedge clk_100MHz or posedge rst) begin
        if(rst) begin
            // 复位时，计数器清零，输出时钟置为低电平
            cnt1k <= 17'd0;
            clk_1kHz <= 1'b0;
        end else begin
            // 当计数器计数到 49999 时
            if(cnt1k == 17'd49999) begin
                cnt1k <= 17'd0;      // 计数器清零，准备下一个周期
                clk_1kHz <= ~clk_1kHz; // 翻转输出时钟的电平
            end else begin
                // 否则，计数器加 1
                cnt1k <= cnt1k + 1'b1;
            end
        end
    end

endmodule
