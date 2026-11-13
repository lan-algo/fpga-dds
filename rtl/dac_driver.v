`timescale 1ns / 1ps

module dac_driver(
    input [7:0] rom_data,      // ROM输出的8位波形数据
    output reg [13:0] dac_data // 14位DAC数据
);

    // 将8位ROM数据转换为14位DAC数据
    // 根据公式：VDIFF = K(2×Q7…Q0 - 255)/256
    // 这里简单地将8位数据左移6位得到14位数据
    always @(*) begin
        dac_data = {rom_data, 6'b000000};
    end

endmodule
