`timescale 1ns / 1ps
//============================================================================
// clk_div.v - 时钟分频器
// 功能：将开发板高频时钟分频为 CPU 所需的低频时钟
// 替代 Vivado 的 Clocking Wizard IP 核
//============================================================================

module clk_div(
    input      clk_in,      // 开发板输入时钟（如 100MHz）
    input      rst,          // 复位
    output reg clk_out       // 分频后的时钟
);

    // TODO: 根据开发板实际时钟频率调整分频系数
    // 示例：100MHz -> 25MHz（4分频）
    // 如果需要手动单步调试，可以改成更低频率

    parameter DIVIDER = 2;   // 分频系数（实际频率 = clk_in / (2 * DIVIDER)）
    reg [31:0] counter;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter <= 32'b0;
            clk_out <= 1'b0;
        end
        else if (counter == DIVIDER - 1) begin
            counter <= 32'b0;
            clk_out <= ~clk_out;
        end
        else begin
            counter <= counter + 1;
        end
    end

endmodule
