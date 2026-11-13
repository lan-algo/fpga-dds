`timescale 1ns / 1ps
// 整数一阶平滑。分别处理增减方向，避免无符号减法回绕。
// 小于一个移位步长的非零差值仍移动1，避免卡在目标值附近。
module freq_smooth_iir #(
    parameter integer SHIFT = 2
)(
    input clk, input clr,
    input [31:0] x_in,
    output reg [31:0] y_out
);
    wire increasing = (x_in >= y_out);
    wire [31:0] distance = increasing ? (x_in - y_out) : (y_out - x_in);
    wire [31:0] scaled_step = distance >> SHIFT;
    wire [31:0] step = (distance != 0 && scaled_step == 0) ? 32'd1 : scaled_step;
    always @(posedge clk or posedge clr) begin
        if (clr) y_out <= 32'd0;
        else if (increasing) y_out <= y_out + step;
        else y_out <= y_out - step;
    end
`ifndef SYNTHESIS
    initial if (SHIFT < 0 || SHIFT > 31) $fatal(1, "SHIFT must be 0..31");
`endif
endmodule
