`timescale 1ns / 1ps
//============================================================================
// idecode.v - RV32I 译码单元
// 功能：寄存器堆读写 + 立即数生成（I/S/B/U/J 五种格式）+ 写回数据选择
//============================================================================

module idecode(
    input         clock,
    input         reset,
    // 指令输入
    input  [31:0] instruction,
    // 控制信号
    input         reg_write,      // 寄存器写使能
    input         mem_to_reg,     // 写回来源：0=ALU, 1=存储器
    input         jal,            // JAL 指令
    input         jalr,           // JALR 指令
    input         lui,            // LUI 指令
    input         auipc,          // AUIPC 指令
    // 写回数据
    input  [31:0] alu_result,     // ALU 运算结果
    input  [31:0] mem_data,       // 从存储器/IO 读出的数据
    input  [31:0] pc,             // 当前 PC
    input  [31:0] pc_plus_4,      // PC + 4
    // 输出
    output [31:0] read_data_1,    // rs1 的值
    output [31:0] read_data_2,    // rs2 的值
    output [31:0] imm_extend      // 扩展后的32位立即数
);

    //========================================================================
    // RV32I 指令字段提取
    //========================================================================
    wire [6:0]  opcode = instruction[6:0];
    wire [4:0]  rs1    = instruction[19:15];
    wire [4:0]  rs2    = instruction[24:20];
    wire [4:0]  rd     = instruction[11:7];
    wire [2:0]  funct3 = instruction[14:12];
    wire [6:0]  funct7 = instruction[31:25];

    //========================================================================
    // 寄存器堆：32 个 32 位寄存器，x0 恒为 0
    //========================================================================
    reg [31:0] registers [0:31];

    assign read_data_1 = (rs1 == 5'b0) ? 32'b0 : registers[rs1];
    assign read_data_2 = (rs2 == 5'b0) ? 32'b0 : registers[rs2];

    //========================================================================
    // 立即数生成器（RV32I 有 5 种立即数格式）
    //========================================================================
    reg [31:0] imm_out;
    assign imm_extend = imm_out;

    always @(*) begin
        case (opcode)
            // I-type: addi, slti, xori, ori, andi, slli, srli, srai, lw, jalr
            7'b0010011, // OP-IMM (addi, etc.)
            7'b0000011, // LOAD (lw, etc.)
            7'b1100111: // JALR
                imm_out = {{20{instruction[31]}}, instruction[31:20]};

            // S-type: sw, sb, sh
            7'b0100011: // STORE
                imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            // B-type: beq, bne, blt, bge, bltu, bgeu
            7'b1100011: // BRANCH
                imm_out = {{19{instruction[31]}}, instruction[31], instruction[7],
                           instruction[30:25], instruction[11:8], 1'b0};

            // U-type: lui, auipc
            7'b0110111, // LUI
            7'b0010111: // AUIPC
                imm_out = {instruction[31:12], 12'b0};

            // J-type: jal
            7'b1101111: // JAL
                imm_out = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                           instruction[20], instruction[30:21], 1'b0};

            default:
                imm_out = 32'b0;
        endcase
    end

    //========================================================================
    // 写回数据选择
    //========================================================================
    reg [31:0] write_data;

    always @(*) begin
        if (jal || jalr)
            write_data = pc_plus_4;          // JAL/JALR: 保存返回地址
        else if (mem_to_reg)
            write_data = mem_data;            // LW: 从存储器读的数据
        else
            write_data = alu_result;          // R-type / I-type: ALU 结果
    end

    //========================================================================
    // 寄存器写入（上升沿写入，x0 不可写）
    //========================================================================
    integer i;
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else if (reg_write && rd != 5'b0) begin
            registers[rd] <= write_data;
        end
    end

endmodule
