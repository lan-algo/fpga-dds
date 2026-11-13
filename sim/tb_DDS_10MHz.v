`timescale 1ns / 1ps
module tb_DDS_10MHz;

    // 输入激励
    reg clk_100MHz;
    reg rst;
    reg [10:0] K;

    // 中间信号
    wire clk_10MHz;    // 分频后10MHz时钟
    wire clk_1kHz;     // 分频后1kHz时钟（可选观测）

    // 波形输出
    wire [7:0] wave_sin;
    wire [7:0] wave_square;
    wire [7:0] wave_tri;
    wire [7:0] wave_saw;

    // DAC输出
    wire [13:0] dac_sin;
    wire [13:0] dac_square;
    wire [13:0] dac_tri;
    wire [13:0] dac_saw;

    // 例化时钟分频器（调用你已有的freq_divider模块）
    freq_divider u_freq_divider(
        .clk_100MHz(clk_100MHz),
        .rst(rst),
        .clk_10MHz(clk_10MHz),
        .clk_1kHz(clk_1kHz)
    );

    // 例化4个DDS模块（需确保DDS模块时钟为clk_10MHz）
    DDS u_dds_sin(
        .clk_10MHz(clk_10MHz),
        .rst(rst),
        .K(K),
        .wave_sel(2'b00),
        .wave_data(wave_sin)
    );

    DDS u_dds_square(
        .clk_10MHz(clk_10MHz),
        .rst(rst),
        .K(K),
        .wave_sel(2'b01),
        .wave_data(wave_square)
    );

    DDS u_dds_tri(
        .clk_10MHz(clk_10MHz),
        .rst(rst),
        .K(K),
        .wave_sel(2'b10),
        .wave_data(wave_tri)
    );

    DDS u_dds_saw(
        .clk_10MHz(clk_10MHz),
        .rst(rst),
        .K(K),
        .wave_sel(2'b11),
        .wave_data(wave_saw)
    );

    // 例化DAC驱动模块（调用你已有的dac_driver模块）
    dac_driver u_dac_sin(
        .rom_data(wave_sin),
        .dac_data(dac_sin)
    );

    dac_driver u_dac_square(
        .rom_data(wave_square),
        .dac_data(dac_square)
    );

    dac_driver u_dac_tri(
        .rom_data(wave_tri),
        .dac_data(dac_tri)
    );

    dac_driver u_dac_saw(
        .rom_data(wave_saw),
        .dac_data(dac_saw)
    );

    // 生成100MHz时钟
    initial begin
        clk_100MHz = 1'b0;
        forever #5 clk_100MHz = ~clk_100MHz; // 周期10ns
    end

    // 激励与测试流程
    initial begin
        rst = 1'b1;
        K = 11'd0;
        #200;  // 复位保持200ns

        rst = 1'b0;
        K = 11'd2047; // 输出频率=10kHz（10MHz时钟下）
        #20_000_000; // 持续20ms

        K = 11'd1023; // 输出频率=20kHz
        #20_000_000; // 持续20ms

        $finish;
    end

    // 波形文件与实时打印
    initial begin
        $dumpfile("tb_DDS_10MHz.vcd");
        $dumpvars(0, tb_DDS_10MHz);
        $monitor("Time=%t, K=%d, 正弦波=%h(DAC=%h), 方波=%h(DAC=%h), 三角波=%h(DAC=%h), 锯齿波=%h(DAC=%h)",
                 $time/1000, K, wave_sin, dac_sin, wave_square, dac_square, wave_tri, dac_tri, wave_saw, dac_saw);
    end

endmodule
