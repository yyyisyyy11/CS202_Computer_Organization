`timescale 1ns / 1ps
//============================================================================
// switchs.v - 拨码开关输入模块
// 功能：读取开发板上24个拨码开关的值，分两次16位读取
//============================================================================

module switchs(
    input         clk,
    input         rst,
    input         switch_read,       // 读使能
    input         switch_cs,         // 片选信号
    input  [1:0]  switch_addr,       // 地址低2位，选择读高/低字节
    output reg [15:0] switch_rdata,  // 送给 CPU 的数据（16位）
    input  [23:0] switch_i           // 开发板上的24个拨码开关
);

    always @(negedge clk or posedge rst) begin
        if (rst) begin
            switch_rdata <= 16'b0;
        end
        else if (switch_cs && switch_read) begin
            case (switch_addr)
                2'b00:   switch_rdata <= switch_i[15:0];             // 低16位
                2'b10:   switch_rdata <= {8'h00, switch_i[23:16]};   // 高8位，零扩展
                default: switch_rdata <= switch_rdata;
            endcase
        end
    end

endmodule
