`timescale 1ns / 1ps
//============================================================================
// dmemory.v - 数据存储器
// 功能：64KB 数据存储器，用 reg 数组实现（不使用 IP 核）
//============================================================================

module dmemory(
    input         clock,
    input         mem_write,      // 写使能
    input  [31:0] address,        // 地址（来自 memorio）
    input  [31:0] write_data,     // 写入数据
    output [31:0] read_data       // 读出数据
);

    // 16K x 32bit = 64KB 数据存储器
    reg [31:0] dmem [0:16383];

    // 异步读取
    assign read_data = dmem[address[15:2]];

    // 同步写入（下降沿，与取指错开）
    always @(negedge clock) begin
        if (mem_write) begin
            dmem[address[15:2]] <= write_data;
        end
    end

endmodule
