`timescale 1ns / 1ps
// 固定 GATE_TIME 个采样时钟为一窗，包含关窗周期检测到的上升沿。
module gate_counter #(
    parameter [31:0] CLK_FREQ = 32'd10000000,
    parameter [31:0] GATE_TIME = 32'd1000000
)(
    input clk, input rst, input signal_in,
    output reg [31:0] frequency
);
    reg [31:0] ticks;
    reg [31:0] pulses;
    reg signal_prev;
    wire rise = signal_in & ~signal_prev;
    wire [32:0] pulses_including_now = {1'b0, pulses} + {32'd0, rise};
    wire [63:0] scaled = {31'd0, pulses_including_now} * {32'd0, CLK_FREQ};
    wire [63:0] measured = scaled / {32'd0, GATE_TIME};
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ticks <= 0; pulses <= 0; frequency <= 0; signal_prev <= 0;
        end else begin
            signal_prev <= signal_in;
            if (ticks == GATE_TIME - 32'd1) begin
                ticks <= 0; pulses <= 0;
                frequency <= measured[63:32] != 0 ? 32'hffffffff : measured[31:0];
            end else begin
                ticks <= ticks + 32'd1;
                pulses <= pulses_including_now[31:0];
            end
        end
    end
`ifndef SYNTHESIS
    initial if (CLK_FREQ == 0 || GATE_TIME == 0) $fatal(1, "clock and gate must be positive");
`endif
endmodule
