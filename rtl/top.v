`timescale 1ns / 1ps

// 顶层模块
module top(
    input clk_100MHz,      // 系统时钟（100MHz）
    input rst,             // 复位信号（高有效）

    input [7:0] K,         // 8位拨码开关（手动频率控制）
    input [3:0] SW_SCAN,   // 扫频范围控制开关
    input [1:0] DIP,       // 显示模式选择DIP开关
    input S0,              // 手动频率增加按键
    input S3,              // 手动频率减少按键
    input S1,              // 扫频复位/关闭按键
    input S4,              // 扫频使能按键
    output [7:0] seg1,     // 数码管段选1
    output [7:0] seg2,     // 数码管段选2
    output [3:0] bit1,     // 数码管位选1
    output [3:0] bit2,     // 数码管位选2
    output [13:0] dac_data,// DAC输出数据（14位）
    output clk_DA,         // DAC驱动时钟
    input [9:0] ad_data,   // ADC输入数据（10位）
    output ad_clk,         // ADC驱动时钟
    output [3:0] debug_leds,// 调试LED
    output pulse_indicator,// 频率测量脉冲指示
    input [1:0] wave_sel   // 波形选择（00-正弦，01-方波，10-三角波等）
);

    // 内部连线定义
    wire [31:0] F;                // 当前输出频率值（显示用）
    wire clk_1kHz;                // 1kHz时钟（数码管扫描）
    wire clk_10MHz;               // 10MHz时钟（DDS/ADC/DAC驱动）
    wire [7:0] wave_data;         // DDS生成的波形数据（8位）
    wire [31:0] adc_frequency_raw;// ADC测量原始频率值
    wire [31:0] adc_frequency_smooth;// ADC测量平滑后频率值
    wire schmitt_out;             // 施密特触发器输出（整形后ADC信号）
    wire [15:0] duty_cycle;       // 占空比测量结果（16位）
    wire [3:0] adc_debug_state;   // ADC调试状态
    wire adc_pulse_led;           // ADC脉冲指示
    wire [10:0] phase_inc;        // 相位增量（最终选择）
    wire [10:0] manual_phase_inc; // 手动模式相位增量
    wire [10:0] sweep_phase_inc;  // 扫频模式相位增量
    wire [31:0] manual_F;         // 手动模式频率值
    wire [31:0] sweep_F;          // 扫频模式频率值

    // 分频模块：100MHz -> 10MHz（系统时钟）和1kHz（数码管扫描）
    freq_divider u_divider(
        .clk_100MHz(clk_100MHz),
        .rst(rst),
        .clk_10MHz(clk_10MHz),
        .clk_1kHz(clk_1kHz)
    );

    // 数码管显示模块：根据DIP选择显示频率/占空比
    LED u_LED(
        .clk_1kHz(clk_1kHz),
        .rst(rst),
        .seg1(seg1),
        .seg2(seg2),
        .bit1(bit1),
        .bit2(bit2),
        .DIP(DIP),
        .F(F),                  // 输出频率
        .adc_frequency(adc_frequency_smooth), // ADC测量频率
        .duty_cycle(duty_cycle) // 占空比
    );

    // 手动频率控制模块：按键/拨码开关控制相位增量和频率
    Frequency_measurement u_freq_calc(
        .K_switch(K),
        .rst(rst),
        .clk_10MHz(clk_10MHz),
        .S0(S0),
        .S3(S3),
        .F(manual_F),
        .phase_inc(manual_phase_inc)
    );

    // 扫频控制模块：生成扫频模式下的相位增量和频率
    sweep_generator u_sweep_gen(
        .clk_10MHz(clk_10MHz),
        .rst(rst),
        .sweep_en(S4),          // 扫频使能
        .sweep_rst(S1),         // 扫频复位
        .SW_SCAN(SW_SCAN),      // 扫频范围选择
        .sweep_phase_inc(sweep_phase_inc),
        .sweep_F(sweep_F)
    );

    // 手动/扫频模式选择器：根据S4选择当前工作模式
    reg [10:0] sel_phase_inc;
    reg [31:0] sel_F;
    always @(*) begin
        if (S4) begin          // 扫频模式
            sel_phase_inc = sweep_phase_inc;
            sel_F = sweep_F;
        end else begin        // 手动模式
            sel_phase_inc = manual_phase_inc;
            sel_F = manual_F;
        end
    end
    assign phase_inc = sel_phase_inc; // 最终相位增量输出
    assign F = sel_F;                 // 最终频率输出

    // DDS核心模块：根据相位增量生成指定波形数据
    DDS u_dds_core(
        .clk_10MHz(clk_10MHz),
        .rst(rst),
        .K(phase_inc),        // 相位增量
        .wave_data(wave_data),// 波形数据输出
        .wave_sel(wave_sel)   // 波形选择
    );

    // DAC驱动模块：将8位波形数据转换为14位DAC输入
    dac_driver u_dac_driver(
        .rom_data(wave_data),
        .dac_data(dac_data)
    );

    // ADC频率测量模块：测量输入信号频率（含施密特整形、滤波）
    adc_frequency_meter u_adc_freq_meter(
        .clk_10MHz(clk_10MHz),
        .rst(rst),
        .ad_data(ad_data),     // ADC原始数据
        .frequency_raw(adc_frequency_raw), // 原始频率值
        .frequency_smooth(adc_frequency_smooth), // 平滑后频率值
        .debug_state(adc_debug_state),      // 调试状态输出
        .pulse_led(adc_pulse_led),          // 脉冲指示
        .schmitt_out(schmitt_out)           // 整形后信号（供占空比测量）
    );

    // 占空比测量模块：测量整形后信号的占空比
    duty_cycle_meter u_duty_meter(
        .clk(clk_10MHz),
        .rst_n(~rst),          // 低有效复位
        .catin(schmitt_out),   // 输入信号（整形后）
        .PonTemp(duty_cycle)   // 占空比结果
    );

    // 时钟分配
    assign clk_DA = clk_10MHz;  // DAC时钟=10MHz
    assign ad_clk = clk_10MHz;  // ADC时钟=10MHz
    // 调试信号输出
    assign debug_leds = adc_debug_state;
    assign pulse_indicator = adc_pulse_led;

endmodule
