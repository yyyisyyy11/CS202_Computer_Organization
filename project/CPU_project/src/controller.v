`timescale 1ns / 1ps
//============================================================================
// controller.v - RV32I 控制单元
// 功能：根据 opcode/funct3/funct7 生成所有控制信号
//============================================================================
// RV32I opcode 编码：
//   R-type:  0110011 (0x33)    I-type:  0010011 (0x13)
//   LOAD:    0000011 (0x03)    STORE:   0100011 (0x23)
//   BRANCH:  1100011 (0x63)    JAL:     1101111 (0x6F)
//   JALR:    1100111 (0x67)    LUI:     0110111 (0x37)
//   AUIPC:   0010111 (0x17)
//============================================================================

module controller(
    input  [6:0]  opcode,
    input  [2:0]  funct3,
    input  [6:0]  funct7,
    input  [21:0] alu_result_high,   // ALU_Result[31:10]，用于 MMIO 地址判断
    // 控制输出
    output        branch,
    output        mem_read,
    output        mem_write,
    output        mem_to_reg,
    output [3:0]  alu_op,
    output        alu_src,
    output        reg_write,
    output        jal,
    output        jalr,
    output        lui,
    output        auipc,
    output        io_read,
    output        io_write
);

    //========================================================================
    // 指令类型判断
    //========================================================================
    wire is_R_type  = (opcode == 7'b0110011);
    wire is_I_type  = (opcode == 7'b0010011);   // OP-IMM (addi, andi, etc.)
    wire is_load    = (opcode == 7'b0000011);
    wire is_store   = (opcode == 7'b0100011);
    wire is_branch  = (opcode == 7'b1100011);
    wire is_jal     = (opcode == 7'b1101111);
    wire is_jalr    = (opcode == 7'b1100111);
    wire is_lui     = (opcode == 7'b0110111);
    wire is_auipc   = (opcode == 7'b0010111);

    //========================================================================
    // I/O 地址判断（ALU结果高22位全1 → I/O 地址空间 ≥ 0xFFFFFC00）
    //========================================================================
    wire is_io_addr = (alu_result_high == 22'h3FFFFF);

    //========================================================================
    // 控制信号
    //========================================================================
    assign branch    = is_branch;
    assign jal       = is_jal;
    assign jalr      = is_jalr;
    assign lui       = is_lui;
    assign auipc     = is_auipc;

    // 寄存器写使能：R/I/LOAD/JAL/JALR/LUI/AUIPC
    assign reg_write = is_R_type | is_I_type | is_load | is_jal | is_jalr | is_lui | is_auipc;

    // ALU 第二操作数来源：1=立即数（I-type, LOAD, STORE）
    assign alu_src   = is_I_type | is_load | is_store;

    // 写回数据来源：1=存储器数据（LOAD）
    assign mem_to_reg = is_load;

    // 存储器读写（非 I/O 地址）
    assign mem_read  = is_load  & ~is_io_addr;
    assign mem_write = is_store & ~is_io_addr;

    // I/O 读写（I/O 地址）
    assign io_read   = is_load  & is_io_addr;
    assign io_write  = is_store & is_io_addr;

    //========================================================================
    // ALU 操作码生成
    //   4'b0000 = ADD       4'b0001 = SUB
    //   4'b0010 = SLL       4'b0011 = SLT
    //   4'b0100 = SLTU      4'b0101 = XOR
    //   4'b0110 = SRL       4'b0111 = SRA
    //   4'b1000 = OR        4'b1001 = AND
    //========================================================================
    reg [3:0] alu_op_reg;
    assign alu_op = alu_op_reg;

    always @(*) begin
        if (is_lui || is_auipc) begin
            alu_op_reg = 4'b0000;   // ADD（LUI/AUIPC 在 execute 中特殊处理）
        end
        else if (is_branch) begin
            alu_op_reg = 4'b0001;   // SUB（用于比较，虽然 ifetch 内部自行判断分支条件）
        end
        else if (is_load || is_store) begin
            alu_op_reg = 4'b0000;   // ADD（地址计算: base + offset）
        end
        else if (is_R_type) begin
            case (funct3)
                3'b000:  alu_op_reg = (funct7[5]) ? 4'b0001 : 4'b0000; // SUB / ADD
                3'b001:  alu_op_reg = 4'b0010; // SLL
                3'b010:  alu_op_reg = 4'b0011; // SLT
                3'b011:  alu_op_reg = 4'b0100; // SLTU
                3'b100:  alu_op_reg = 4'b0101; // XOR
                3'b101:  alu_op_reg = (funct7[5]) ? 4'b0111 : 4'b0110; // SRA / SRL
                3'b110:  alu_op_reg = 4'b1000; // OR
                3'b111:  alu_op_reg = 4'b1001; // AND
                default: alu_op_reg = 4'b0000;
            endcase
        end
        else if (is_I_type) begin
            case (funct3)
                3'b000:  alu_op_reg = 4'b0000; // ADDI
                3'b001:  alu_op_reg = 4'b0010; // SLLI
                3'b010:  alu_op_reg = 4'b0011; // SLTI
                3'b011:  alu_op_reg = 4'b0100; // SLTIU
                3'b100:  alu_op_reg = 4'b0101; // XORI
                3'b101:  alu_op_reg = (funct7[5]) ? 4'b0111 : 4'b0110; // SRAI / SRLI
                3'b110:  alu_op_reg = 4'b1000; // ORI
                3'b111:  alu_op_reg = 4'b1001; // ANDI
                default: alu_op_reg = 4'b0000;
            endcase
        end
        else begin
            alu_op_reg = 4'b0000;   // 默认 ADD
        end
    end

endmodule
