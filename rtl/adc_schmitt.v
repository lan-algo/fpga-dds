`timescale 1ns / 1ps

module adc_schmitt #(
    parameter integer MID_CODE = 512,  // 中点
    parameter integer HYS      = 10    // 滞回宽度
)(
    input        clk,       // 10MHz
    input        clr,       // 高有效
    input  [9:0] ad_in,     // ADC (0..1023)
    output reg   sig_lvl    // 数字方波
);
    // 边界保护的阈值计算
    wire [9:0] th_hi = (MID_CODE + HYS > 1023) ? 10'd1023 : (MID_CODE + HYS);
    wire [9:0] th_lo = (MID_CODE > HYS) ? (MID_CODE - HYS) : 10'd0;

    always @(posedge clk or posedge clr) begin
        if (clr)
            sig_lvl <= 1'b0;
        else begin
            if (!sig_lvl) begin
                // 当前低电平，需要超过高阈值才跳变
                if (ad_in >= th_hi)
                    sig_lvl <= 1'b1;
            end else begin
                // 当前高电平，需要低于低阈值才跳变
                if (ad_in <= th_lo)
                    sig_lvl <= 1'b0;
            end
        end
    end
endmodule
