`timescale 1ns / 1ps

// 辅助模块采用同名独立文件；详见 docs/provenance.md。
module adc_frequency_meter(
    input clk_10MHz,           // 10MHz系统时钟
    input rst,                 // 系统复位信号（高有效）
    input [9:0] ad_data,       // 10位ADC输入数据
    output [31:0] frequency_raw,  // 原始测量频率输出
    output [31:0] frequency_smooth, // 平滑滤波后的频率输出
    output [3:0] debug_state,  // 调试状态输出
    output pulse_led,          // 脉冲指示LED驱动信号
    output schmitt_out         // 施密特触发器输出（供调试用）
);

    wire sync_rise;            // 同步后的信号上升沿脉冲
    wire [31:0] freq_gate;     // 闸门计数法测量结果
    wire [31:0] freq_period_fast; // 快速周期测量法结果（少周期平均）
    wire [31:0] freq_period_slow; // 慢速周期测量法结果（多周期平均）
    reg [31:0] freq_period;    // 最终选择的周期测量法结果
    reg [31:0] selected_freq;  // 最终选择的频率测量结果

    // 例化施密特触发器模块
    adc_schmitt #(
        .MID_CODE(512),
        .HYS(9)
    ) u_schmitt (
        .clk(clk_10MHz),
        .clr(rst),
        .ad_in(ad_data),
        .sig_lvl(schmitt_out)
    );

    // 例化同步边沿检测模块
    sync_edge u_sync (
        .clk(clk_10MHz),
        .clr(rst),
        .sig_in(schmitt_out),
        .rise_p(sync_rise)
    );

    // 例化闸门计数法模块
    gate_counter #(
        .CLK_FREQ(10000000),
        .GATE_TIME(1000000) // 100ms闸门时间
    ) u_gate_counter (
        .clk(clk_10MHz),
        .rst(rst),
        .signal_in(schmitt_out),
        .frequency(freq_gate)
    );

    // 例化快速周期平均法模块（测量10个周期）
    period_counter_avg #(
        .F_REF_HZ(10000000),
        .N_CYCLES(10)
    ) u_period_fast (
        .clk_ref(clk_10MHz),
        .clr(rst),
        .rise_p(sync_rise),
        .freq_hz(freq_period_fast)
    );

    // 例化慢速周期平均法模块（测量100个周期）
    period_counter_avg #(
        .F_REF_HZ(10000000),
        .N_CYCLES(100)
    ) u_period_slow (
        .clk_ref(clk_10MHz),
        .clr(rst),
        .rise_p(sync_rise),
        .freq_hz(freq_period_slow)
    );

    // 周期测量法内部选择逻辑：在极低频时选择快速测量，以缩短响应时间
    always @(posedge clk_10MHz or posedge rst) begin
        if (rst) begin
            freq_period <= 32'd0;
        end else begin
            // 快速结果先到即可使用；低于50Hz也不必等待100周期。
            if (freq_period_fast > 32'd0 && (freq_period_fast < 32'd50 || freq_period_slow == 0)) begin
                freq_period <= freq_period_fast;
            end else begin
                // 否则使用慢速测量结果（N_CYCLES=100），精度更高
                freq_period <= freq_period_slow;
            end
        end
    end

    // 全局测量方法选择逻辑：选择闸门计数法或周期平均法的结果
    always @(posedge clk_10MHz or posedge rst) begin
        if (rst) begin
            selected_freq <= 32'd0;
        end else begin
            // 高频段 (1kHz ~ 2.5MHz)，使用闸门计数法
            if (freq_gate > 32'd1000 && freq_gate < 32'd2500000) begin
                selected_freq <= freq_gate;
            end
            // 低频段 (<= 1kHz)，使用周期平均法
            else if (freq_period > 32'd0 && freq_period <= 32'd1000) begin
                selected_freq <= freq_period;
            end
            // 默认情况下，使用闸门计数法的结果
            else begin
                selected_freq <= freq_gate;
            end
        end
    end

    // 例化IIR平滑滤波模块
    freq_smooth_iir #(
        .SHIFT(2) // α=1/4
    ) u_smooth (
        .clk(clk_10MHz),
        .clr(rst),
        .x_in(selected_freq),
        .y_out(frequency_smooth)
    );

    // 模块输出赋值
    assign frequency_raw = selected_freq;  // 输出原始测量频率
    assign pulse_led = sync_rise;          // 将上升沿脉冲输出到LED，用于观察信号
    // 调试状态输出
    assign debug_state[0] = (ad_data > 10'd0); // ADC是否有输入
    assign debug_state[1] = schmitt_out;       // 施密特触发器输出状态
    assign debug_state[2] = sync_rise;         // 是否检测到上升沿
    assign debug_state[3] = (selected_freq > 32'd0); // 是否测量到有效频率

endmodule
