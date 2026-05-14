`timescale 1ns / 1ps
//============================================================================
// execute.v - RV32I 执行单元（ALU）
// 功能：根据 alu_op 执行运算，支持 LUI/AUIPC 特殊处理
// 支持：ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND + LUI + AUIPC
//============================================================================

module execute(
    input  [31:0] read_data_1,    // rs1 的值
    input  [31:0] read_data_2,    // rs2 的值
    input  [31:0] imm_extend,     // 扩展后立即数
    input  [31:0] pc,             // 当前 PC
    input  [3:0]  alu_op,         // ALU 操作码
    input         alu_src,        // 0=rs2, 1=立即数
    input  [2:0]  funct3,         // 指令的 funct3 字段
    input         funct7_5,       // funct7[5]，区分 ADD/SUB, SRL/SRA
    input         lui,            // LUI 指令标志
    input         auipc,          // AUIPC 指令标志
    // 输出
    output [31:0] alu_result,     // ALU 运算结果
    output        zero            // 零标志
);

    //========================================================================
    // 操作数选择
    //========================================================================
    wire [31:0] alu_input_a = (auipc) ? pc : read_data_1;
    wire [31:0] alu_input_b = (alu_src) ? imm_extend : read_data_2;

    //========================================================================
    // ALU 核心运算
    //========================================================================
    reg [31:0] alu_out;

    always @(*) begin
        if (lui) begin
            alu_out = imm_extend;   // LUI: 直接输出 {imm[31:12], 12'b0}
        end
        else begin
            case (alu_op)
                4'b0000: alu_out = alu_input_a + alu_input_b;                              // ADD / ADDI
                4'b0001: alu_out = alu_input_a - alu_input_b;                              // SUB
                4'b0010: alu_out = alu_input_a << alu_input_b[4:0];                        // SLL / SLLI
                4'b0011: alu_out = ($signed(alu_input_a) < $signed(alu_input_b)) ? 32'd1 : 32'd0;  // SLT / SLTI
                4'b0100: alu_out = (alu_input_a < alu_input_b) ? 32'd1 : 32'd0;           // SLTU / SLTIU
                4'b0101: alu_out = alu_input_a ^ alu_input_b;                              // XOR / XORI
                4'b0110: alu_out = alu_input_a >> alu_input_b[4:0];                        // SRL / SRLI
                4'b0111: alu_out = $signed(alu_input_a) >>> alu_input_b[4:0];              // SRA / SRAI
                4'b1000: alu_out = alu_input_a | alu_input_b;                              // OR / ORI
                4'b1001: alu_out = alu_input_a & alu_input_b;                              // AND / ANDI
                default: alu_out = 32'b0;
            endcase
        end
    end

    assign alu_result = alu_out;
    assign zero = (alu_out == 32'b0);

endmodule
