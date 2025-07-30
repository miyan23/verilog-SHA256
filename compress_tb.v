`timescale 1ns / 1ps

module compress_tb ();

  // 时钟和复位信号
  reg clk;
  reg rst_n;

  // 压缩模块输入
  reg [31:0] Wt_in;
  reg Wt_valid;
  reg [255:0] hash_in;

  // 压缩模块输出
  wire [255:0] hash_out;
  wire hash_out_valid;

  // 测试向量
  reg [31:0] test_W[0:63];  // 测试用的Wt值
  reg [255:0] initial_hash;  // 初始哈希值

  // 实例化被测模块
  compress uut (
      .clk(clk),
      .rst_n(rst_n),
      .Wt_in(Wt_in),
      .Wt_valid(Wt_valid),
      .hash_in(hash_in),
      .hash_out(hash_out),
      .hash_out_valid(hash_out_valid)
  );

  // 时钟生成（周期10ns）
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // 测试过程
  initial begin
    // =============================================
    // 初始化测试向量
    // =============================================
    // 使用标准SHA-256测试向量
    initial_hash = 256'h6a09e667_bb67ae85_3c6ef372_a54ff53a_510e527f_9b05688c_1f83d9ab_5be0cd19;

    // 填充测试Wt值（来自"abc"消息的扩展结果）
    test_W[0] = 32'h61626380;
    test_W[1] = 32'h00000000;
    test_W[2] = 32'h00000000;
    test_W[3] = 32'h00000000;
    test_W[4] = 32'h00000000;
    test_W[5] = 32'h00000000;
    test_W[6] = 32'h00000000;
    test_W[7] = 32'h00000000;
    test_W[8] = 32'h00000000;
    test_W[9] = 32'h00000000;
    test_W[10] = 32'h00000000;
    test_W[11] = 32'h00000000;
    test_W[12] = 32'h00000000;
    test_W[13] = 32'h00000000;
    test_W[14] = 32'h00000000;
    test_W[15] = 32'h00000018;
    // 扩展部分
    test_W[16] = 32'h61626380;
    test_W[17] = 32'h000f0000;
    test_W[18] = 32'h7da86405;
    test_W[19] = 32'h00000000;
    test_W[20] = 32'h00000000;
    test_W[21] = 32'h00000000;
    test_W[22] = 32'h00000000;
    test_W[23] = 32'h00000000;
    test_W[24] = 32'h00000000;
    test_W[25] = 32'h00000000;
    test_W[26] = 32'h00000000;
    test_W[27] = 32'h00000000;
    test_W[28] = 32'h00000000;
    test_W[29] = 32'h00000000;
    test_W[30] = 32'h00000000;
    test_W[31] = 32'h00000000;
    test_W[32] = 32'h00000000;
    test_W[33] = 32'h00000000;
    test_W[34] = 32'h00000000;
    test_W[35] = 32'h00000000;
    test_W[36] = 32'h00000000;
    test_W[37] = 32'h00000000;
    test_W[38] = 32'h00000000;
    test_W[39] = 32'h00000000;
    test_W[40] = 32'h00000000;
    test_W[41] = 32'h00000000;
    test_W[42] = 32'h00000000;
    test_W[43] = 32'h00000000;
    test_W[44] = 32'h00000000;
    test_W[45] = 32'h00000000;
    test_W[46] = 32'h00000000;
    test_W[47] = 32'h00000000;
    test_W[48] = 32'h00000000;
    test_W[49] = 32'h00000000;
    test_W[50] = 32'h00000000;
    test_W[51] = 32'h00000000;
    test_W[52] = 32'h00000000;
    test_W[53] = 32'h00000000;
    test_W[54] = 32'h00000000;
    test_W[55] = 32'h00000000;
    test_W[56] = 32'h00000000;
    test_W[57] = 32'h00000000;
    test_W[58] = 32'h00000000;
    test_W[59] = 32'h00000000;
    test_W[60] = 32'h00000000;
    test_W[61] = 32'h00000000;
    test_W[62] = 32'h00000000;
    test_W[63] = 32'h12b1edeb;

    // =============================================
    // 测试用例1：基本功能测试
    // =============================================
    $display("\n[TEST CASE 1] Basic functionality test");

    // 初始化
    #20;
    rst_n = 0;
    Wt_in = 0;
    Wt_valid = 0;
    hash_in = 0;
    #10;

    // 释放复位
    rst_n = 1;
    #10;

    // 设置初始哈希值
    hash_in = initial_hash;

    // 开始发送Wt值
    for (integer t = 0; t < 64; t = t + 1) begin
      @(posedge clk);
      Wt_in = test_W[t];
      Wt_valid = 1;
      @(posedge clk);
      Wt_valid = 0;
    end

    // 等待最终哈希输出
    wait (hash_out_valid);
    #0.1;
    $display("First block final hash: %h", hash_out);

    // =============================================
    // 测试用例2：连续块处理测试
    // =============================================
    $display("\n[TEST CASE 2] Continuous block processing test");

    // 使用第一个块的输出作为第二个块的输入
    #20;
    hash_in = hash_out;

    // 发送第二个块的Wt值（使用不同的测试向量）
    for (integer t = 0; t < 64; t = t + 1) begin
      @(posedge clk);
      Wt_in = test_W[t] + 32'h100;  // 修改Wt值以模拟不同的消息块
      Wt_valid = 1;
      @(posedge clk);
      Wt_valid = 0;
    end

    // 等待最终哈希输出
    wait (hash_out_valid);
    #0.1;
    $display("Second block final hash: %h", hash_out);

    // =============================================
    // 测试用例3：边界条件测试 - 复位测试
    // =============================================
    $display("\n[TEST CASE 3] Reset test");

    // 在压缩过程中复位
    hash_in = initial_hash;

    // 开始发送Wt值
    for (integer t = 0; t < 16; t = t + 1) begin
      @(posedge clk);
      Wt_in = test_W[t];
      Wt_valid = 1;
      @(posedge clk);
      Wt_valid = 0;
    end

    // 在压缩过程中触发复位
    #50;
    rst_n = 0;
    #20;
    rst_n = 1;

    // 验证输出是否被复位
    if (hash_out_valid === 0) begin
      $display("[RESULT] PASS: Reset correctly deasserted hash_out_valid");
    end else begin
      $display("[RESULT] FAIL: Reset did not deassert hash_out_valid");
    end

    // =============================================
    // 结束仿真
    // =============================================
    #100;
    $display("\n[SIMULATION FINISHED]");
    $finish;
  end

  // 波形转储
  initial begin
    $dumpfile("compress.vcd");
    $dumpvars(0, compress_tb);
  end

endmodule
