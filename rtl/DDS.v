`timescale 1ns / 1ps

// ROM 抽出为 sin_rom.v，其余波形逻辑保持课程版本。
module square_wave_gen(
    input clk,              // 时钟信号
    input rst,              // 复位信号（高有效）
    input [10:0] phase_acc, // 11位相位累加器值
    output reg [7:0] square_data // 8位方波输出
);

// 组合逻辑生成方波
always @(*) begin
    // 复位时输出低电平（0）
    square_data = rst ? 8'd0 :
                  // 利用相位累加器的最高位（第10位）来控制方波的高低电平
                  // 当最高位为 1 时，输出高电平（255）；为 0 时，输出低电平（0）
                  // 由于相位累加器是线性增长的，最高位会周期性翻转，从而形成方波
                  (phase_acc[10] ? 8'd255 : 8'd0);
end
endmodule

// 三角波生成模块
// 根据相位累加器的值生成三角波
module triangle_wave_gen(
    input clk,              // 时钟信号
    input rst,              // 复位信号（高有效）
    input [10:0] phase_acc, // 11位相位累加器值
    output reg [7:0] triangle_data // 8位三角波输出
);

// 将 11 位相位累加器值缩减为 9 位，用于生成三角波
// 这样做是为了降低三角波的频率，使其与其他波形频率匹配
wire [8:0] phase_9bit = phase_acc[10:2];

// 组合逻辑生成三角波
always @(*) begin
    // 复位时输出低电平（0）
    triangle_data = rst ? 8'd0 :
                    // 利用 9 位相位值的最高位（第8位）来控制三角波的上升和下降沿
                    // 当最高位为 1 时，对低 8 位进行按位取反，实现下降沿
                    // 当最高位为 0 时，直接使用低 8 位，实现上升沿
                    (phase_9bit[8] ? ~phase_9bit[7:0] : phase_9bit[7:0]);
end
endmodule

// 锯齿波生成模块
// 根据相位累加器的值生成锯齿波
module sawtooth_wave_gen(
    input clk,              // 时钟信号
    input rst,              // 复位信号（高有效）
    input [10:0] phase_acc, // 11位相位累加器值
    output reg [7:0] sawtooth_data // 8位锯齿波输出
);

// 组合逻辑生成锯齿波
always @(*) begin
    if (rst) begin
        // 复位时输出低电平（0）
        sawtooth_data = 8'd0;
    end else begin
        // 直接截取相位累加器的高 8 位（bit10 ~ bit3）作为锯齿波输出
        // 由于相位累加器在每个时钟周期都会增加一个固定值 K，
        // 其高 8 位会线性增长，当达到最大值后会溢出归零，从而形成锯齿波
        sawtooth_data = phase_acc[10:3];
    end
end
endmodule

// 直接数字频率合成器（DDS）顶层模块
// 该模块可以生成正弦波、方波、三角波和锯齿波，
// 并通过频率控制字 K 调整输出波形的频率，通过 wave_sel 选择输出波形
module DDS(
    input clk_10MHz,        // 系统时钟，频率为 10MHz
    input rst,              // 全局复位信号（高有效）
    input [10:0] K,         // 11位频率控制字，用于调整输出波形的频率
    input [1:0] wave_sel,   // 2位波形选择信号：00-正弦波，01-方波，10-三角波，11-锯齿波
    output reg [7:0] wave_data // 8位波形输出数据
);

parameter N = 11;          // 相位累加器的位数
// 分频时钟在复位时停止；等待ROM完成首次同步读出，避免DAC出现未定义数据。
reg rom_ready;
always @(posedge clk_10MHz or posedge rst) begin
    if (rst) rom_ready <= 1'b0;
    else rom_ready <= 1'b1;
end

reg [N-1:0] phase_accumulator; // 11位相位累加器，用于产生线性增长的相位
wire [7:0] rom_address;        // 连接到正弦波 ROM 的 8 位地址线
wire [7:0] sin_data;           // 从正弦波 ROM 读出的数据
wire [7:0] square_data;        // 方波生成模块的输出
wire [7:0] triangle_data;      // 三角波生成模块的输出
wire [7:0] sawtooth_data;      // 锯齿波生成模块的输出

// 相位累加器模块
// 相位累加器是 DDS 的核心，它在每个时钟周期都会累加一个频率控制字 K
always @(posedge clk_10MHz or posedge rst) begin
    if (rst) begin
        // 复位时，相位累加器清零
        phase_accumulator <= {N{1'b0}};
    end else begin
        // 每个时钟周期，相位累加器的值增加 K
        phase_accumulator <= phase_accumulator + K;
    end
end

// 从 11 位相位累加器中截取高 8 位作为正弦波 ROM 的地址
// 这样做是因为 ROM 只有 256 个地址（0-255）
assign rom_address = phase_accumulator[10:3];

// 例化各个波形生成模块
// 正弦波 ROM 模块
sin_rom u_sin_rom(
    .clka(clk_10MHz),
    .addra(rom_address),
    .douta(sin_data)
);

// 方波生成模块
square_wave_gen u_square_gen(
    .clk(clk_10MHz),
    .rst(rst),
    .phase_acc(phase_accumulator),
    .square_data(square_data)
);

// 三角波生成模块
triangle_wave_gen u_triangle_gen(
    .clk(clk_10MHz),
    .rst(rst),
    .phase_acc(phase_accumulator),
    .triangle_data(triangle_data)
);

// 锯齿波生成模块
sawtooth_wave_gen u_sawtooth_gen(
    .clk(clk_10MHz),
    .rst(rst),
    .phase_acc(phase_accumulator),
    .sawtooth_data(sawtooth_data)
);

// 波形选择与输出模块
// 根据 wave_sel 信号选择不同的波形数据输出
always @(posedge clk_10MHz or posedge rst) begin
    if (rst) begin
        // 复位时，输出低电平
        wave_data <= 8'd0;
    end else begin
        // 根据波形选择信号，将相应的波形数据赋值给输出端口
        case(wave_sel)
            2'b00: wave_data <= rom_ready ? sin_data : 8'd0;       // 输出正弦波
            2'b01: wave_data <= square_data;    // 输出方波
            2'b10: wave_data <= triangle_data;  // 输出三角波
            2'b11: wave_data <= sawtooth_data; // 输出锯齿波
            default: wave_data <= rom_ready ? sin_data : 8'd0;     // 默认情况下输出正弦波
        endcase
    end
end
endmodule
