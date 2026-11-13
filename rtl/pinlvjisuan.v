`timescale 1ns / 1ps

module Frequency_measurement(
    input clk_10MHz,         // 10MHz时钟
    input rst,               // 高有效复位
    input [7:0] K_switch,    // 8位开关输入（高8位频率控制字）
    input S0,                // 频率增加按钮
    input S3,                // 频率减少按钮

    output [31:0] F,         // 计算出的频率值（Hz）
    output [10:0] phase_inc  // 11位完整频率控制字（高8位+低3位微步）
);


    parameter [16:0] DEBOUNCE_COUNT = 17'd100000; // 消抖计数（10MHz时钟下10ms）



    reg [2:0] frac_sel = 3'd0;      // 低3位微步选择（0-7）

    // 按钮消抖相关信号
    reg btn_plus_d1, btn_plus_d2;   // 增加按钮同步寄存器
    reg btn_plus_stable;            // 增加按钮稳定状态
    reg [16:0] btn_plus_counter;    // 增加按钮消抖计数器

    reg btn_minus_d1, btn_minus_d2; // 减少按钮同步寄存器
    reg btn_minus_stable;           // 减少按钮稳定状态
    reg [16:0] btn_minus_counter;   // 减少按钮消抖计数器

    // 按钮上升沿检测信号
    reg btn_plus_stable_d1, btn_minus_stable_d1;
    wire btn_plus_rise, btn_minus_rise;

    // 11位完整频率控制字（高8位来自开关，低3位来自微步选择）
    assign phase_inc = {K_switch, frac_sel};



    // ====================== 增加按钮消抖逻辑 ======================
    always @(posedge clk_10MHz or posedge rst) begin
        if (rst) begin
            btn_plus_d1 <= 1'b0;
            btn_plus_d2 <= 1'b0;
            btn_plus_stable <= 1'b0;
            btn_plus_counter <= 17'd0;
        end else begin
            // 同步输入信号（降低亚稳态传播风险）
            btn_plus_d1 <= S0;
            btn_plus_d2 <= btn_plus_d1;

            // 消抖逻辑：状态变化时计数，计数满后确认状态
            if (btn_plus_d2 != btn_plus_stable) begin
                if (btn_plus_counter < DEBOUNCE_COUNT) begin
                    btn_plus_counter <= btn_plus_counter + 17'd1;
                end else begin
                    btn_plus_stable <= btn_plus_d2;
                    btn_plus_counter <= 17'd0;
                end
            end else begin
                // 状态稳定时重置计数器
                btn_plus_counter <= 17'd0;
            end
        end
    end

    // ====================== 减少按钮消抖逻辑 ======================
    always @(posedge clk_10MHz or posedge rst) begin
        if (rst) begin
            btn_minus_d1 <= 1'b0;
            btn_minus_d2 <= 1'b0;
            btn_minus_stable <= 1'b0;
            btn_minus_counter <= 17'd0;
        end else begin
            // 同步输入信号（降低亚稳态传播风险）
            btn_minus_d1 <= S3;
            btn_minus_d2 <= btn_minus_d1;

            // 消抖逻辑：状态变化时计数，计数满后确认状态
            if (btn_minus_d2 != btn_minus_stable) begin
                if (btn_minus_counter < DEBOUNCE_COUNT) begin
                    btn_minus_counter <= btn_minus_counter + 17'd1;
                end else begin
                    btn_minus_stable <= btn_minus_d2;
                    btn_minus_counter <= 17'd0;
                end
            end else begin
                // 状态稳定时重置计数器
                btn_minus_counter <= 17'd0;
            end
        end
    end

    // ====================== 按钮上升沿检测 ======================
    always @(posedge clk_10MHz or posedge rst) begin
        if (rst) begin
            btn_plus_stable_d1 <= 1'b0;
            btn_minus_stable_d1 <= 1'b0;
        end else begin
            btn_plus_stable_d1 <= btn_plus_stable;
            btn_minus_stable_d1 <= btn_minus_stable;
        end
    end

    // 上升沿检测（按钮按下时产生一个时钟周期的高电平）
    assign btn_plus_rise = ~btn_plus_stable_d1 & btn_plus_stable;
    assign btn_minus_rise = ~btn_minus_stable_d1 & btn_minus_stable;

    // ====================== 微步选择控制 ======================
    always @(posedge clk_10MHz or posedge rst) begin
        if (rst) begin
            frac_sel <= 3'd0;
        end else if (btn_plus_rise) begin
            // 增加按钮按下：微步值加1，循环计数（0-7）
            frac_sel <= (frac_sel == 3'd7) ? 3'd0 : (frac_sel + 3'd1);
        end else if (btn_minus_rise) begin
            // 减少按钮按下：微步值减1，循环计数（0-7）
            frac_sel <= (frac_sel == 3'd0) ? 3'd7 : (frac_sel - 3'd1);
        end
    end

    // 频率计算公式：F = (phase_inc * clk_freq) / 2^N
    // 其中 clk_freq = 10MHz，N=11（2^11=2048）
    wire [63:0] mul64 = (64'd10000000 * {{53{1'b0}}, phase_inc}); // 64位乘法避免溢出
    wire [63:0] hz_wide = mul64 >> 11;
    assign F = hz_wide[31:0]; // 最大K=2047，对应名义频率小于10MHz。

endmodule
