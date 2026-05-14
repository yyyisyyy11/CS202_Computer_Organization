`timescale 1ns / 1ps
//============================================================================
// leds.v - LED 输出模块
// 功能：控制开发板上24个LED灯的输出，分两次16位写入
//============================================================================

module leds(
    input         clk,
    input         rst,
    input         led_write,         // 写使能
    input         led_cs,            // 片选信号
    input  [1:0]  led_addr,          // 地址低2位，选择写高/低字节
    input  [15:0] led_wdata,         // 要写入的数据（16位）
    output reg [23:0] led_out        // 输出到开发板LED
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            led_out <= 24'h000000;
        end
        else if (led_cs && led_write) begin
            case (led_addr)
                2'b00:   led_out <= {led_out[23:16], led_wdata[15:0]};    // 写低16位
                2'b10:   led_out <= {led_wdata[7:0], led_out[15:0]};      // 写高8位
                default: led_out <= led_out;
            endcase
        end
    end

endmodule
