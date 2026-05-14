`timescale 1ns / 1ps
//============================================================================
// ifetch.v - RV32I 取指单元
// 功能：管理 PC、指令存储器、下一条 PC 的选择（顺序/分支/跳转）
// 指令存储器使用 readmemh 加载 batch_test.hex
//============================================================================

module ifetch(
    input         clock,
    input         reset,
    // 控制信号
    input         branch,         // 分支指令标志
    input  [2:0]  funct3,         // 分支类型（beq/bne/blt/bge/bltu/bgeu）
    input         jal,            // JAL 指令
    input         jalr,           // JALR 指令
    // 数据输入
    input  [31:0] read_data_1,    // rs1 的值（JALR、分支比较用）
    input  [31:0] read_data_2,    // rs2 的值（分支比较用）
    input  [31:0] imm_extend,     // 扩展后立即数（分支偏移/JAL偏移/JALR偏移）
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

    assign instruction = imem[PC[15:2]];  // 按字对齐

    //========================================================================
    // 分支条件判断（覆盖 RV32I 全部 6 种分支指令）
    //========================================================================
    reg branch_taken;

    always @(*) begin
        if (branch) begin
            case (funct3)
                3'b000:  branch_taken = (read_data_1 == read_data_2);                          // BEQ
                3'b001:  branch_taken = (read_data_1 != read_data_2);                          // BNE
                3'b100:  branch_taken = ($signed(read_data_1) < $signed(read_data_2));         // BLT
                3'b101:  branch_taken = ($signed(read_data_1) >= $signed(read_data_2));        // BGE
                3'b110:  branch_taken = (read_data_1 < read_data_2);                           // BLTU
                3'b111:  branch_taken = (read_data_1 >= read_data_2);                          // BGEU
                default: branch_taken = 1'b0;
            endcase
        end
        else begin
            branch_taken = 1'b0;
        end
    end

    //========================================================================
    // 下一条 PC 计算
    // 优先级：JALR > JAL > Branch(taken) > PC+4
    //========================================================================
    reg [31:0] next_pc;

    always @(*) begin
        if (jalr)
            next_pc = (read_data_1 + imm_extend) & 32'hFFFFFFFE;  // JALR: rs1 + imm, 最低位清零
        else if (jal)
            next_pc = PC + imm_extend;                             // JAL: PC + offset
        else if (branch_taken)
            next_pc = PC + imm_extend;                             // Branch taken: PC + offset
        else
            next_pc = pc_plus_4;                                   // 顺序执行: PC + 4
    end

    //========================================================================
    // PC 更新（下降沿，与寄存器写入错开避免冲突）
    //========================================================================
    always @(negedge clock) begin
        if (reset)
            PC <= 32'h00000000;
        else
            PC <= next_pc;
    end

endmodule
