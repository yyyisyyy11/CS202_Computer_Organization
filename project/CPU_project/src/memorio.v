`timescale 1ns / 1ps
//============================================================================
// memorio.v - 存储器/IO 地址分配器
// 功能：根据地址高位判断访问目标是存储器还是 I/O 设备
// 地址空间：高位全1 → I/O，否则 → 存储器
//============================================================================

module memorio(
    input  [31:0] caddress,       // 来自 ALU 的计算地址
    input         mem_read,       // 存储器读使能
    input         mem_write,      // 存储器写使能
    input         io_read,        // I/O 读使能
    input         io_write,       // I/O 写使能
    input  [31:0] mem_rdata,      // 从数据存储器读出的数据
    input  [15:0] io_rdata,       // 从 I/O 读出的数据（16位）
    input  [31:0] wdata,          // 要写的数据（来自 rs2）
    output [31:0] rdata,          // 读出的数据（送回寄存器堆）
    output [31:0] write_data,     // 写入存储器/IO 的数据
    output [31:0] address,        // 传给存储器和 I/O 的地址
    output        led_ctrl,       // LED 片选信号
    output        switch_ctrl     // 拨码开关片选信号
);

    assign address = caddress;

    // 读数据选择：I/O 读时取低16位零扩展，否则取存储器数据
    assign rdata = (io_read) ? {16'h0000, io_rdata} : mem_rdata;

    // 写数据处理：I/O 写时只写低16位
    reg [31:0] write_data_reg;
    assign write_data = write_data_reg;

    always @(*) begin
        if (mem_write || io_write)
            write_data_reg = (mem_write) ? wdata : {16'b0, wdata[15:0]};
        else
            write_data_reg = 32'h00000000;
    end

    // 片选信号
    assign led_ctrl    = io_write;
    assign switch_ctrl = io_read;

endmodule
