`timescale 1ns / 1ps

module expand_tb ();

  // 时钟和复位信号
  reg clk;
  reg rst_n;

  // 模块输入
  reg [511:0] block_in;
  reg block_valid;

  // 模块输出
  wire [31:0] Wt_out;
  wire Wt_valid;

  // 用于收集Wt值的数组
  reg [31:0] W[0:63];
  reg [511:0] block2;

  // 收集所有64个Wt值
  integer t;
  // 收集第一个块的Wt值
  integer block1_count;
  // 收集第二个块的Wt值
  integer block2_count;

  // 实例化被测模块
  expand uut (
      .clk(clk),
      .rst_n(rst_n),
      .block_in(block_in),
      .block_valid(block_valid),
      .Wt_out(Wt_out),
      .Wt_valid(Wt_valid)
  );

  // 时钟生成（周期10ns）
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // 测试过程
  initial begin
    // =============================================
    // 测试用例1：基本功能测试 - 验证前16个字直接输出
    // =============================================
    $display("\n[TEST CASE 1] Basic functionality test - first 16 words");

    // 初始化
    #20;
    rst_n = 0;
    block_in = 0;
    block_valid = 0;
    #10;

    // 释放复位
    rst_n = 1;
    #10;

    // 准备测试数据块 (前16个字设置为0-15)
    for (integer i = 0; i < 16; i = i + 1) begin
      block_in[511-32*i-:32] = i;
    end

    // 发送有效块
    @(posedge clk);
    block_valid = 1;
    @(posedge clk);
    block_valid = 0;

    // 等待16个周期的流水线延迟
    repeat (16) @(posedge clk);

    // 检查前16个输出
    for (integer t = 0; t < 16; t = t + 1) begin
      wait (Wt_valid);
      #0.1;  // 确保输出稳定
      $display("W[%0d] = %h", t, Wt_out);

      if (Wt_out !== t) begin
        $display("[RESULT] FAIL: W[%0d] expected %h, got %h", t, t, Wt_out);
      end else begin
        $display("[RESULT] PASS: W[%0d] correct", t);
      end

      @(posedge clk);
    end

    // =============================================
    // 测试用例2：扩展功能测试 - 验证后48个字的生成
    // =============================================
    $display("\n[TEST CASE 2] Expand test - verify words 16-63");

    // 等待当前扩展完成
    while (Wt_valid) @(posedge clk);
    #10;

    // 准备新的测试数据块 (使用SHA-256标准测试向量)
    block_in = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;

    // 发送有效块
    @(posedge clk);
    block_valid = 1;
    @(posedge clk);
    block_valid = 0;

    t = 0;
    while (t < 64) begin
      if (Wt_valid) begin
        W[t] = Wt_out;
        $display("W[%0d] = %h", t, Wt_out);
        t = t + 1;
      end
      @(posedge clk);
    end

    // 验证扩展结果 (对比预计算的SHA-256扩展值)
    // 注意：这里只验证部分关键点，实际测试中应验证所有64个字

    // 验证W[16] (第一个扩展字)
    if (W[16] === 32'h61626380) begin
      $display("[RESULT] PASS: W[16] correct");
    end else begin
      $display("[RESULT] FAIL: W[16] expected 61626380, got %h", W[16]);
    end

    // 验证W[17] (第二个扩展字)
    if (W[17] === 32'h000f0000) begin
      $display("[RESULT] PASS: W[17] correct");
    end else begin
      $display("[RESULT] FAIL: W[17] expected 000f0000, got %h", W[17]);
    end

    // 验证W[18] (第三个扩展字)
    if (W[18] === 32'h7da86405) begin
      $display("[RESULT] PASS: W[18] correct");
    end else begin
      $display("[RESULT] FAIL: W[18] expected 7da86405, got %h", W[18]);
    end

    // 验证W[63] (最后一个扩展字)
    if (W[63] === 32'h12b1edeb) begin
      $display("[RESULT] PASS: W[63] correct");
    end else begin
      $display("[RESULT] FAIL: W[63] expected 12b1edeb, got %h", W[63]);
    end

    // =============================================
    // 测试用例3：流水线功能测试 - 验证连续块处理
    // =============================================
    $display("\n[TEST CASE 3] Pipeline test - verify continuous block processing");

    // 发送第一个块
    @(posedge clk);
    block_valid = 1;
    block_in = 512'h6162636462636465636465666465666765666768666768696768696a68696a6b696a6b6c6a6b6c6d6b6c6d6e6c6d6e6f6d6e6f706e6f70718000000000000000;
    @(posedge clk);
    block_valid = 0;

    // 在第一个块处理过程中发送第二个块
    #100;  // 等待部分处理完成
    @(posedge clk);
    block_valid = 1;
    block_in = 512'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c0;
    @(posedge clk);
    block_valid  = 0;

    block1_count = 0;
    while (block1_count < 64) begin
      if (Wt_valid) begin
        $display("Block1 W[%0d] = %h", block1_count, Wt_out);
        block1_count = block1_count + 1;
      end
      @(posedge clk);
    end

    block2_count = 0;
    while (block2_count < 64) begin
      if (Wt_valid) begin
        $display("Block2 W[%0d] = %h", block2_count, Wt_out);
        block2_count = block2_count + 1;
      end
      @(posedge clk);
    end

    // 验证第二个块的最后一个字是否正确
    if (Wt_out === 32'hb9018b52) begin
      $display("[RESULT] PASS: Second block processing finished correctly");
    end else begin
      $display("[RESULT] FAIL: Second block last word expected b9018b52, got %h", Wt_out);
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
    $dumpfile("expand.vcd");
    $dumpvars(0, expand_tb);
  end

endmodule
