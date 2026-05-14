`timescale 1ns / 1ps
//============================================================================
// TopDebug_tb.v - 顶层仿真 Testbench
// 功能：对 TopDebug 进行功能仿真验证
//============================================================================

module TopDebug_tb();

    reg         clk;
    reg         rst;
    reg  [23:0] switch2N4;
    wire [23:0] led2N4;

    // 实例化被测模块
    TopDebug uut(
        .clk(clk),
        .rst(rst),
        .switch2N4(switch2N4),
        .led2N4(led2N4)
    );

    // 时钟生成：10ns 周期（100MHz）
    initial clk = 0;
    always #5 clk = ~clk;

    // 内部信号引用（方便调试观察）
    wire [31:0] current_pc   = uut.pc;
    wire [31:0] current_inst = uut.instruction;
    wire [31:0] alu_out      = uut.alu_result;

    // 测试流程
    initial begin
        $dumpfile("TopDebug_tb.vcd");
        $dumpvars(0, TopDebug_tb);

        // 初始化
        rst = 1;
        switch2N4 = 24'b0;

        // 复位释放
        #100;
        rst = 0;

        // ================================================================
        // 用例0：AND 运算
        // 输入: A=0x0F (低8位), B=0x37 (高8位)
        // 期望: 0x0F & 0x37 = 0x07
        // ================================================================
        switch2N4 = {8'h00, 8'h37, 8'h0F};  // switch[7:0]=0x0F, switch[15:8]=0x37
        #500;
        $display("[Test0 AND] Input: A=0x0F, B=0x37, LED=%h (expect 0x07)", led2N4);

        // ================================================================
        // 用例1：SLL 逻辑左移
        // 输入: 操作数=0x01, 移位量=3
        // 期望: 0x01 << 3 = 0x08
        // ================================================================
        switch2N4 = {8'h00, 8'h03, 8'h01};  // data=0x01, shift=3
        #500;
        $display("[Test1 SLL] Input: data=0x01, shift=3, LED=%h (expect 0x08)", led2N4);

        // ================================================================
        // 用例7：Popcount
        // 输入: 0xB4 = 10110100 → 1的个数 = 4
        // ================================================================
        switch2N4 = {16'h0000, 8'hB4};
        #2000;
        $display("[Test7 Popcount] Input: 0xB4, LED=%h (expect 0x04)", led2N4);

        // ================================================================
        // 用例6：斐波那契 fib(10) = 55
        // ================================================================
        switch2N4 = {16'h0000, 8'h0A};  // n=10
        #5000;
        $display("[Test6 Fibonacci] Input: n=10, LED=%h (expect 0x37=55)", led2N4);

        // 结束仿真
        #1000;
        $display("=== Simulation Complete ===");
        $finish;
    end

    // 每个时钟周期监控 PC 变化
    always @(posedge clk) begin
        if (!rst)
            $display("t=%0t | PC=%h | Inst=%h | ALU=%h | LED=%h",
                     $time, current_pc, current_inst, alu_out, led2N4);
    end

endmodule
