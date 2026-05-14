`timescale 1ns / 1ps
//============================================================================
// TopDebug.v - RV32I CPU 顶层模块
// 功能：连接所有子模块，映射开发板 I/O（拨码开关、LED）
// 注意：工程名 cpu_project，顶层模块名 TopDebug，bitstream 名 TopDebug.bit
//============================================================================

module TopDebug(
    input         clk,           // 开发板时钟（如 100MHz）
    input         rst,           // 复位信号（高有效）
    input  [23:0] switch2N4,     // 24位拨码开关输入
    output [23:0] led2N4         // 24位LED输出
);

    //========================================================================
    // 时钟分频（替代 IP 核）
    //========================================================================
    wire cpu_clk;
    clk_div clk_divider(
        .clk_in(clk),
        .rst(rst),
        .clk_out(cpu_clk)
    );

    //========================================================================
    // 内部信号声明
    //========================================================================

    // --- 取指单元信号 ---
    wire [31:0] instruction;     // 当前指令
    wire [31:0] pc;              // 当前 PC 值
    wire [31:0] pc_plus_4;       // PC + 4

    // --- 控制单元信号 ---
    wire        branch;          // 分支指令标志
    wire        mem_read;        // 存储器读
    wire        mem_write;       // 存储器写
    wire        mem_to_reg;      // 写回数据来源：0=ALU结果, 1=存储器数据
    wire [3:0]  alu_op;          // ALU 操作码
    wire        alu_src;         // ALU 第二操作数来源：0=rs2, 1=立即数
    wire        reg_write;       // 寄存器写使能
    wire        jal;             // JAL 指令标志
    wire        jalr;            // JALR 指令标志
    wire        lui;             // LUI 指令标志
    wire        auipc;           // AUIPC 指令标志
    wire        io_read;         // I/O 读
    wire        io_write;        // I/O 写

    // --- 译码单元信号 ---
    wire [31:0] read_data_1;     // rs1 的值
    wire [31:0] read_data_2;     // rs2 的值
    wire [31:0] imm_extend;      // 扩展后的32位立即数

    // --- 执行单元信号 ---
    wire [31:0] alu_result;      // ALU 运算结果
    wire        zero;            // ALU 零标志
    wire [31:0] branch_target;   // 分支目标地址

    // --- 存储器信号 ---
    wire [31:0] mem_read_data;   // 从数据存储器读出的数据
    wire [31:0] address;         // 访存地址（经 memorio 处理）
    wire [31:0] write_data;      // 写入存储器/IO 的数据
    wire [31:0] read_data;       // 从存储器或 IO 读出的数据（送回寄存器堆）

    // --- I/O 信号 ---
    wire [15:0] io_read_data;    // 从 I/O 读取的数据
    wire        led_ctrl;        // LED 片选
    wire        switch_ctrl;     // 拨码开关片选
    wire [15:0] switch_rdata;    // 拨码开关读出的数据

    //========================================================================
    // 模块实例化
    //========================================================================

    // 1. 取指单元
    ifetch fetch_unit(
        .clock(cpu_clk),
        .reset(rst),
        .branch(branch),
        .zero(zero),
        .jal(jal),
        .jalr(jalr),
        .alu_result(alu_result),
        .imm_extend(imm_extend),
        .read_data_1(read_data_1),
        .instruction(instruction),
        .pc(pc),
        .pc_plus_4(pc_plus_4)
    );

    // 2. 译码单元（寄存器堆 + 立即数生成）
    idecode decode_unit(
        .clock(cpu_clk),
        .reset(rst),
        .instruction(instruction),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .jal(jal),
        .jalr(jalr),
        .lui(lui),
        .auipc(auipc),
        .alu_result(alu_result),
        .mem_data(read_data),
        .pc(pc),
        .pc_plus_4(pc_plus_4),
        .read_data_1(read_data_1),
        .read_data_2(read_data_2),
        .imm_extend(imm_extend)
    );

    // 3. 控制单元
    controller ctrl_unit(
        .opcode(instruction[6:0]),
        .funct3(instruction[14:12]),
        .funct7(instruction[31:25]),
        .alu_result_high(alu_result[31:10]),
        .branch(branch),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_op(alu_op),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .jal(jal),
        .jalr(jalr),
        .lui(lui),
        .auipc(auipc),
        .io_read(io_read),
        .io_write(io_write)
    );

    // 4. 执行单元（ALU）
    execute exec_unit(
        .read_data_1(read_data_1),
        .read_data_2(read_data_2),
        .imm_extend(imm_extend),
        .pc(pc),
        .alu_op(alu_op),
        .alu_src(alu_src),
        .funct3(instruction[14:12]),
        .funct7_5(instruction[30]),
        .lui(lui),
        .auipc(auipc),
        .alu_result(alu_result),
        .zero(zero)
    );

    // 5. 数据存储器（用 reg 数组实现，不用 IP 核）
    dmemory data_mem(
        .clock(cpu_clk),
        .mem_write(mem_write & ~io_write),  // 非 I/O 地址时才写存储器
        .address(address),
        .write_data(write_data),
        .read_data(mem_read_data)
    );

    // 6. MemorIO - 存储器/IO 地址分配
    memorio mem_io(
        .caddress(alu_result),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .io_read(io_read),
        .io_write(io_write),
        .mem_rdata(mem_read_data),
        .io_rdata(io_read_data),
        .wdata(read_data_2),
        .rdata(read_data),
        .write_data(write_data),
        .address(address),
        .led_ctrl(led_ctrl),
        .switch_ctrl(switch_ctrl)
    );

    // 7. I/O 读取多路选择器
    ioread io_read_mux(
        .reset(rst),
        .ior(io_read),
        .switch_ctrl(switch_ctrl),
        .io_read_data_switch(switch_rdata),
        .io_read_data(io_read_data)
    );

    // 8. 拨码开关输入
    switchs switch_input(
        .clk(cpu_clk),
        .rst(rst),
        .switch_read(io_read),
        .switch_cs(switch_ctrl),
        .switch_addr(address[1:0]),
        .switch_rdata(switch_rdata),
        .switch_i(switch2N4)
    );

    // 9. LED 输出
    leds led_output(
        .clk(cpu_clk),
        .rst(rst),
        .led_write(io_write),
        .led_cs(led_ctrl),
        .led_addr(address[1:0]),
        .led_wdata(write_data[15:0]),
        .led_out(led2N4)
    );

endmodule
