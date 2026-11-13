`timescale 1ns / 1ps

// 数码管显示模块：根据DIP开关选择显示学号/年份、输出频率、ADC测量频率或占空比
module LED(
    input clk_1kHz,          // 1kHz扫描时钟（用于数码管动态刷新）
    input rst,               // 复位信号（高有效）
    input [1:0] DIP,         // 显示模式选择开关（00-学号年份，01-输出频率，10-ADC频率，11-占空比）
    input [31:0] F,          // DDS输出频率值
    input [31:0] adc_frequency, // ADC测量频率值
    input [15:0] duty_cycle, // 占空比测量值
    output reg [7:0] seg1,   // 第一组数码管段选信号（学号/频率低位）
    output reg [7:0] seg2,   // 第二组数码管段选信号（年份/频率高位）
    output reg [3:0] bit1,   // 第一组数码管位选信号
    output reg [3:0] bit2    // 第二组数码管位选信号
);



    // 八位显示最大99999999；先限定范围，再提取0..9，显式保留4位。
    function [3:0] decimal_digit;
        input [31:0] value;
        input [31:0] divisor;
        reg [31:0] bounded, remainder;
        begin
            bounded = value > 32'd99999999 ? 32'd99999999 : value;
            remainder = (bounded / divisor) % 32'd10;
            decimal_digit = remainder[3:0];
        end
    endfunction

    // 第二组数码管各位缓存（EO23/频率高位）
    reg [3:0] q_2; // E
    reg [3:0] b_2; // O
    reg [3:0] s_2; // 2
    reg [3:0] g_2; // 3

    // 第一组数码管各位缓存（学号0000/频率低位）
    reg [3:0] q_1; // 0
    reg [3:0] b_1; // 4
    reg [3:0] s_1; // 2
    reg [3:0] g_1; // 0

    // 七段数码管段码表（共阴极，8位含小数点）
    reg [7:0] seg_table [0:15];
    initial begin
        seg_table[0] = 8'h3f; // 数字0
        seg_table[1] = 8'h06; // 数字1
        seg_table[2] = 8'h5b; // 数字2
        seg_table[3] = 8'h4f; // 数字3
        seg_table[4] = 8'h66; // 数字4
        seg_table[5] = 8'h6d; // 数字5
        seg_table[6] = 8'h7d; // 数字6
        seg_table[7] = 8'h07; // 数字7
        seg_table[8] = 8'h7f; // 数字8
        seg_table[9] = 8'h6f; // 数字9
        seg_table[10] = 8'h79; // 字母E
        seg_table[11] = 8'h3f; // 字母O（复用0的段码）
    end

    // 扫描索引计数器（0-7，控制8个数码管位选）
    reg [2:0] bit_idx;
    always @(posedge clk_1kHz or posedge rst)
    begin
        if(rst)
            bit_idx <= 3'd0; // 复位清零
        else if(bit_idx == 3'd7)
            bit_idx <= 3'd0; // 循环计数
        else
            bit_idx <= bit_idx + 3'd1;
     end

     // 组合逻辑：根据扫描索引控制位选和段选
     always @(*)
     begin
        q_1=0; b_1=0; s_1=0; g_1=0; q_2=0; b_2=0; s_2=0; g_2=0;
        // 默认值（消隐）
        bit1 = 4'b0000;
        bit2 = 4'b0000;
        seg1 = 8'h00;
        seg2 = 8'h00;

        // 位选逻辑：分时点亮不同数码管
        case(bit_idx)
            // 第一组数码管（学号/频率低位）
            3'd0: begin bit1 = 4'b0001; bit2 = 4'b0000; end // 个位
            3'd1: begin bit1 = 4'b0010; bit2 = 4'b0000; end // 十位
            3'd2: begin bit1 = 4'b0100; bit2 = 4'b0000; end // 百位
            3'd3: begin bit1 = 4'b1000; bit2 = 4'b0000; end // 千位

            // 第二组数码管（年份/频率高位）
            3'd4: begin bit1 = 4'b0000; bit2 = 4'b0001; end // 个位
            3'd5: begin bit1 = 4'b0000; bit2 = 4'b0010; end // 十位
            3'd6: begin bit1 = 4'b0000; bit2 = 4'b0100; end // 百位
            3'd7: begin bit1 = 4'b0000; bit2 = 4'b1000; end // 千位

            default: begin bit1 = 4'b0000; bit2 = 4'b0000; end
        endcase

        // 段选逻辑：根据DIP选择显示内容
        if( DIP == 2'b00 )// 显示电光23（EO23）和学号（0000）
        begin
            // EO23分解赋值
            q_2 = 4'd10; // E
            b_2 = 4'd11; // O
            s_2 = 4'd2;  // 2
            g_2 = 4'd3;  // 3

            // 学号0000分解赋值
            q_1 = 4'd0;  // 0
            b_1 = 4'd0;  // 4
            s_1 = 4'd0;  // 2
            g_1 = 4'd0;  // 0

            // 按扫描索引输出段码
            case(bit_idx)
                // 第一组数码管（学号）
                3'd0: begin seg1 = seg_table[g_1]; seg2 = 8'h00; end // 个位0
                3'd1: begin seg1 = seg_table[s_1]; seg2 = 8'h00; end // 十位2
                3'd2: begin seg1 = seg_table[b_1]; seg2 = 8'h00; end // 百位4
                3'd3: begin seg1 = seg_table[q_1]; seg2 = 8'h00; end // 千位0

                // 第二组数码管（EO23）
                3'd4: begin seg1 = 8'h00; seg2 = seg_table[g_2]+8'b10000000; end // 3（带小数点）
                3'd5: begin seg1 = 8'h00; seg2 = seg_table[s_2]; end // 2
                3'd6: begin seg1 = 8'h00; seg2 = seg_table[b_2]; end // O
                3'd7: begin seg1 = 8'h00; seg2 = seg_table[q_2]; end // E

                default: begin seg1 = 8'h00; seg2 = 8'h00; end
            endcase
        end
        else if (DIP == 2'b01)// 显示DDS输出频率F
        begin
            // 频率值分解为各位（千万位到个位）
            q_2 = decimal_digit(F, 32'd10000000);     // 千万位
            b_2 = decimal_digit(F, 32'd1000000); // 百万位
            s_2 = decimal_digit(F, 32'd100000);   // 十万位
            g_2 = decimal_digit(F, 32'd10000);     // 万位

            q_1 = decimal_digit(F, 32'd1000);  // 千位
            b_1 = decimal_digit(F, 32'd100);    // 百位
            s_1 = decimal_digit(F, 32'd10);      // 十位
            g_1 = decimal_digit(F, 32'd1);            // 个位

            // 按扫描索引输出段码（千位带小数点）
            case(bit_idx)
                3'd0: begin seg1 = seg_table[g_1]; seg2 = 8'h00; end // 个位
                3'd1: begin seg1 = seg_table[s_1]; seg2 = 8'h00; end // 十位
                3'd2: begin seg1 = seg_table[b_1]; seg2 = 8'h00; end // 百位
                3'd3: begin seg1 = seg_table[q_1]+8'b10000000; seg2 = 8'h00; end // 千位（带小数点）

                3'd4: begin seg1 = 8'h00; seg2 = seg_table[g_2]; end // 万位
                3'd5: begin seg1 = 8'h00; seg2 = seg_table[s_2]; end // 十万位
                3'd6: begin seg1 = 8'h00; seg2 = seg_table[b_2]; end // 百万位
                3'd7: begin seg1 = 8'h00; seg2 = seg_table[q_2]; end // 千万位

                default: begin seg1 = 8'h00; seg2 = 8'h00; end
            endcase
        end
        else if (DIP == 2'b10)// 显示ADC测量频率（直接显示，不添加常数补偿）
        begin
            // 直接分解测量频率，移除无依据的+3补偿
            q_2 = decimal_digit(adc_frequency, 32'd10000000);
            b_2 = decimal_digit(adc_frequency, 32'd1000000);
            s_2 = decimal_digit(adc_frequency, 32'd100000);
            g_2 = decimal_digit(adc_frequency, 32'd10000);

            q_1 = decimal_digit(adc_frequency, 32'd1000);
            b_1 = decimal_digit(adc_frequency, 32'd100);
            s_1 = decimal_digit(adc_frequency, 32'd10);
            g_1 = decimal_digit(adc_frequency, 32'd1);

            // 段码输出逻辑同频率显示
            case(bit_idx)
                3'd0: begin seg1 = seg_table[g_1]; seg2 = 8'h00; end
                3'd1: begin seg1 = seg_table[s_1]; seg2 = 8'h00; end
                3'd2: begin seg1 = seg_table[b_1]; seg2 = 8'h00; end
                3'd3: begin seg1 = seg_table[q_1]+8'b10000000; seg2 = 8'h00; end

                3'd4: begin seg1 = 8'h00; seg2 = seg_table[g_2]; end
                3'd5: begin seg1 = 8'h00; seg2 = seg_table[s_2]; end
                3'd6: begin seg1 = 8'h00; seg2 = seg_table[b_2]; end
                3'd7: begin seg1 = 8'h00; seg2 = seg_table[q_2]; end

                default: begin seg1 = 8'h00; seg2 = 8'h00; end
            endcase
        end
        else if (DIP == 2'b11)// 显示占空比（百位带小数点）
        begin
            // 占空比值分解
            q_2 = decimal_digit({16'd0, duty_cycle}, 32'd10000000);
            b_2 = decimal_digit({16'd0, duty_cycle}, 32'd1000000);
            s_2 = decimal_digit({16'd0, duty_cycle}, 32'd100000);
            g_2 = decimal_digit({16'd0, duty_cycle}, 32'd10000);

            q_1 = decimal_digit({16'd0, duty_cycle}, 32'd1000);
            b_1 = decimal_digit({16'd0, duty_cycle}, 32'd100);
            s_1 = decimal_digit({16'd0, duty_cycle}, 32'd10);
            g_1 = decimal_digit({16'd0, duty_cycle}, 32'd1);

            // 段码输出（百位带小数点）
            case(bit_idx)
                3'd0: begin seg1 = seg_table[g_1]; seg2 = 8'h00; end // 个位
                3'd1: begin seg1 = seg_table[s_1]; seg2 = 8'h00; end // 十位
                3'd2: begin seg1 = seg_table[b_1]+8'b10000000; seg2 = 8'h00; end // 百位（带小数点）
                3'd3: begin seg1 = seg_table[q_1]; seg2 = 8'h00; end // 千位

                3'd4: begin seg1 = 8'h00; seg2 = seg_table[g_2]; end // 万位
                3'd5: begin seg1 = 8'h00; seg2 = seg_table[s_2]; end // 十万位
                3'd6: begin seg1 = 8'h00; seg2 = seg_table[b_2]; end // 百万位
                3'd7: begin seg1 = 8'h00; seg2 = seg_table[q_2]; end // 千万位

                default: begin seg1 = 8'h00; seg2 = 8'h00; end
            endcase
        end
    end
endmodule
