`timescale 1ns / 1ps
//============================================================================
// ioread.v - I/O 读取多路选择器
// 功能：根据片选信号选择从哪个外设读取数据
//============================================================================

module ioread(
    input         reset,
    input         ior,               // I/O 读使能
    input         switch_ctrl,       // 拨码开关片选
    input  [15:0] io_read_data_switch,  // 来自拨码开关的数据
    output reg [15:0] io_read_data   // 送给 memorio 的数据
);

    always @(*) begin
        if (reset)
            io_read_data = 16'b0;
        else if (ior && switch_ctrl)
            io_read_data = io_read_data_switch;
        else
            io_read_data = 16'b0;
    end

endmodule
