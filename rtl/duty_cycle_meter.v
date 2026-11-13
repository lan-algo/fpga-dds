`timescale 1ns / 1ps
// 在相邻同步上升沿之间统计完整周期；输出四舍五入的整数百分比。
module duty_cycle_meter #(
    parameter [31:0] TIMEOUT_TICKS = 32'd20000000
)(
    input clk, input rst_n, input catin,
    output reg [15:0] PonTemp
);
    reg sync1, sync2, sync_delayed;
    reg started;
    reg [31:0] high_ticks, period_ticks;
    wire rise = sync2 & ~sync_delayed;
    wire [63:0] scaled_high = {32'd0, high_ticks} * 64'd100;
    wire [63:0] percentage = period_ticks != 0 ?
        (scaled_high + ({32'd0, period_ticks} >> 1)) / {32'd0, period_ticks} : 64'd0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync1 <= 0; sync2 <= 0; sync_delayed <= 0;
            started <= 0; high_ticks <= 0; period_ticks <= 0; PonTemp <= 0;
        end else begin
            sync1 <= catin; sync2 <= sync1; sync_delayed <= sync2;
            if (rise) begin
                if (started && period_ticks != 0)
                    PonTemp <= percentage > 64'd100 ? 16'd100 : percentage[15:0];
                // 当前上升沿属于下一周期，其第一个高电平采样必须计入。
                started <= 1; high_ticks <= 1; period_ticks <= 1;
            end else if (started) begin
                if (period_ticks >= TIMEOUT_TICKS) begin
                    started <= 0; high_ticks <= 0; period_ticks <= 0; PonTemp <= 0;
                end else begin
                    period_ticks <= period_ticks + 32'd1;
                    if (sync2) high_ticks <= high_ticks + 32'd1;
                end
            end
        end
    end
`ifndef SYNTHESIS
    initial if (TIMEOUT_TICKS == 0) $fatal(1, "TIMEOUT_TICKS must be positive");
`endif
endmodule
