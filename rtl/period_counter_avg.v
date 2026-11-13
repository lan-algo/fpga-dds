`timescale 1ns / 1ps
// 第一条边沿仅建立时间基准；之后统计N个完整周期。
module period_counter_avg #(
    parameter [31:0] F_REF_HZ = 32'd10000000,
    parameter [31:0] N_CYCLES = 32'd200,
    parameter [31:0] TIMEOUT_TICKS = F_REF_HZ * 32'd2
)(
    input clk_ref, input clr, input rise_p,
    output reg [31:0] freq_hz
);
    reg [31:0] tick_cnt, last_tick, cycle_count, idle_ticks;
    reg [63:0] sum_ticks;
    reg started;
    localparam [63:0] NUMERATOR = {32'd0, F_REF_HZ} * {32'd0, N_CYCLES};
    wire [31:0] delta_ticks = tick_cnt - last_tick;
    wire [63:0] sum_all = sum_ticks + {32'd0, delta_ticks};
    wire [63:0] quotient = sum_all != 0 ? (NUMERATOR + (sum_all >> 1)) / sum_all : 64'd0;
    always @(posedge clk_ref or posedge clr) begin
        if (clr) begin
            tick_cnt <= 0; last_tick <= 0; cycle_count <= 0; idle_ticks <= 0;
            sum_ticks <= 0; freq_hz <= 0; started <= 0;
        end else begin
            tick_cnt <= tick_cnt + 32'd1;
            if (rise_p) begin
                idle_ticks <= 0; last_tick <= tick_cnt;
                if (!started) begin
                    started <= 1; cycle_count <= 0; sum_ticks <= 0;
                end else if (cycle_count == N_CYCLES - 32'd1) begin
                    freq_hz <= quotient[63:32] != 0 ? 32'hffffffff : quotient[31:0];
                    cycle_count <= 0; sum_ticks <= 0;
                end else begin
                    cycle_count <= cycle_count + 32'd1;
                    sum_ticks <= sum_all;
                end
            end else if (idle_ticks >= TIMEOUT_TICKS - 32'd1) begin
                // 默认约2秒无边沿，清除过期结果并等待重新捕获。
                started <= 0; cycle_count <= 0; sum_ticks <= 0; freq_hz <= 0;
            end else idle_ticks <= idle_ticks + 32'd1;
        end
    end
`ifndef SYNTHESIS
    initial if (F_REF_HZ == 0 || F_REF_HZ > 32'd1000000000 || N_CYCLES == 0 || N_CYCLES > 32'd65535 || TIMEOUT_TICKS == 0)
        $fatal(1, "invalid period counter parameters");
`endif
endmodule
