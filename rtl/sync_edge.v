`timescale 1ns / 1ps

module sync_edge(
    input  clk,         // 参考时钟域（10MHz）
    input  clr,         // 复位（高有效）
    input  sig_in,      // 待测数字信号
    output reg rise_p   // 上升沿单拍
);
    reg ff1, ff2, ff2_d;

    always @(posedge clk or posedge clr) begin
        if (clr) begin
            ff1   <= 1'b0;
            ff2   <= 1'b0;
            ff2_d <= 1'b0;
            rise_p<= 1'b0;
        end else begin
            ff1   <= sig_in;        // 第一级同步
            ff2   <= ff1;           // 第二级同步
            ff2_d <= ff2;           // 延迟一级
            rise_p<= (~ff2_d) & ff2; // 上升沿检测
        end
    end
endmodule
