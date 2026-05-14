`timescale 1ns / 1ps
//============================================================================
// ifetch.v - RV32I 取指单元
// 功能：管理 PC、指令存储器、下一条 PC 的选择（顺序/分支/跳转）
// 注意：指令存储器使用 readmemh 加载 batch_test.hex
//============================================================================

module ifetch(
    input         clock,
    input         reset,
    // 控制信号
    input         branch,         // 分支使能
    input         zero,           // ALU 零标志
    input         jal,            // JAL 指令
    input         jalr,           // JALR 指令
    // 数据输入
    input  [31:0] alu_result,     // ALU 结果（JALR 用）
    input  [31:0] imm_extend,     // 扩展后立即数（分支偏移/JAL偏移）
    input  [31:0] read_data_1,    // rs1 的值（JALR 用）
    // 输出
    output [31:0] instruction,    // 当前指令
    output [31:0] pc,             // 当前 PC
    output [31:0] pc_plus_4       // PC + 4
);

    //========================================================================
    // PC 寄存器
    //========================================================================
    reg [31:0] PC;
    assign pc = PC;
    assign pc_plus_4 = PC + 32'd4;

    //========================================================================
    // 指令存储器（64KB，使用 readmemh 初始化）
    //========================================================================
    reg [31:0] imem [0:16383];  // 16K x 32bit = 64KB

    initial begin
        $readmemh("batch_test.hex", imem);
    end

    assign instruction = imem[PC[15:2]];  // 按字对齐，PC[1:0]忽略

    //========================================================================
    // 下一条 PC 计算
    //========================================================================
    reg [31:0] next_pc;

    always @(*) begin
        // TODO: 根据控制信号选择下一条 PC
        // 优先级：JALR > JAL > Branch(taken) > PC+4
        if (jalr) begin
            next_pc = (read_data_1 + imm_extend) & 32'hFFFFFFFE;  // 最低位清零
        end
        else if (jal) begin
            next_pc = PC + imm_extend;
        end
        else if (branch && zero) begin
            // TODO: 这里需要根据 funct3 判断不同的分支条件
            // 目前仅处理 beq（zero==1 时跳转）
            // 完整实现需要把 branch 条件判断逻辑补全
            next_pc = PC + imm_extend;
        end
        else begin
            next_pc = pc_plus_4;
        end
    end

    //========================================================================
    // PC 更新（下降沿）
    //========================================================================
    always @(negedge clock) begin
        if (reset)
            PC <= 32'h00000000;
        else
            PC <= next_pc;
    end

endmodule
