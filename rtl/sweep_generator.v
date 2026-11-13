`timescale 1ns / 1ps
// 保留原控制字区间；区间不是报告注释所写的1Hz起调频。
module sweep_generator #(
    parameter [10:0] STEP_SIZE = 11'd1,
    parameter [16:0] DELAY_CNT = 17'd131071
)(
    input clk_10MHz, input rst, input sweep_en, input sweep_rst,
    input [3:0] SW_SCAN,
    output reg [10:0] sweep_phase_inc,
    output [31:0] sweep_F
);
    reg [16:0] step_delay;
    wire [10:0] min_word = SW_SCAN[3] ? 11'd0 : SW_SCAN[2] ? 11'd2 :
                           SW_SCAN[1] ? 11'd21 : SW_SCAN[0] ? 11'd205 : 11'd0;
    wire [10:0] max_word = SW_SCAN[3] ? 11'd2 : SW_SCAN[2] ? 11'd21 :
                           SW_SCAN[1] ? 11'd205 : 11'd2047;
    wire reset_all = rst | sweep_rst;
    wire [11:0] candidate = {1'b0, sweep_phase_inc} + {1'b0, STEP_SIZE};
    wire [63:0] frequency_wide = (64'd10000000 * {53'd0, sweep_phase_inc}) >> 11;
    // K最大2047，名义频率小于10MHz，明确取32位不会丢失有效数值。
    assign sweep_F = frequency_wide[31:0];
    always @(posedge clk_10MHz or posedge reset_all) begin
        if (reset_all) begin step_delay <= 0; sweep_phase_inc <= 0; end
        else if (sweep_phase_inc < min_word || sweep_phase_inc > max_word) begin
            step_delay <= 0; sweep_phase_inc <= min_word;
        end else if (sweep_en) begin
            // DELAY_CNT+1周期更新一次：默认131072 / 10MHz = 13.1072ms。
            if (step_delay == DELAY_CNT) begin
                step_delay <= 0;
                if (candidate > {1'b0,max_word}) sweep_phase_inc <= min_word;
                else sweep_phase_inc <= candidate[10:0];
            end else step_delay <= step_delay + 17'd1;
        end else step_delay <= 0;
    end
endmodule
