`timescale 1ns / 1ps

module top_tb ();

  // 时钟和复位信号
  reg             clk;
  reg             rst_n;

  // 模块输入
  reg     [  7:0] data_in;
  reg             data_in_valid;
  reg             data_last;

  // 模块输出
  wire    [255:0] hash_out;
  wire            hash_out_valid;
  wire            data_ready;

  // 测试向量
  reg     [  7:0] test_message                     [0:63];  // 测试消息存储
  integer         message_length;  // 消息长度
  integer         i;  // 循环计数器

  // 实例化被测模块
  top uut (
      .clk(clk),
      .rst_n(rst_n),
      .data_in(data_in),
      .data_in_valid(data_in_valid),
      .data_last(data_last),
      .hash_out(hash_out),
      .hash_out_valid(hash_out_valid),
      .data_ready(data_ready)
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

    // 测试用例1: "abc"消息 (标准SHA-256测试向量)
    test_message[0] = "a";
    test_message[1] = "b";
    test_message[2] = "c";
    message_length  = 3;

    // =============================================
    // 测试用例1：基本功能测试 - "abc"消息
    // =============================================
    $display("\n[TEST CASE 1] Testing 'abc' message (standard test vector)");

    // 初始化
    #20;
    rst_n = 0;
    data_in = 0;
    data_in_valid = 0;
    data_last = 0;
    #10;

    // 释放复位
    rst_n = 1;
    #10;

    // 等待模块就绪
    wait (data_ready);
    @(posedge clk);

    // 发送消息
    for (i = 0; i < message_length; i = i + 1) begin
      data_in = test_message[i];
      data_in_valid = 1;
      data_last = (i == message_length - 1);
      @(posedge clk);
    end

    // 结束输入
    data_in_valid = 0;
    data_last = 0;

    // 等待哈希输出
    wait (hash_out_valid);
    #0.1;

    // 显示结果
    $display("\nFinal hash:");
    $display("%h %h %h %h", hash_out[255:224], hash_out[223:192], hash_out[191:160],
             hash_out[159:128]);
    $display("%h %h %h %h", hash_out[127:96], hash_out[95:64], hash_out[63:32], hash_out[31:0]);

    // 验证结果 (标准SHA-256("abc")结果)
    if (hash_out === 256'hba7816bf_8f01cfea_414140de_5dae2223_b00361a3_96177a9c_b410ff61_f20015ad) begin
      $display("[RESULT] PASS: Hash matches expected value for 'abc'");
    end else begin
      $display("[RESULT] FAIL: Hash mismatch for 'abc'");
      $display("Expected: ba7816bf_8f01cfea_414140de_5dae2223_b00361a3_96177a9c_b410ff61_f20015ad");
      $display("Received: %h", hash_out);
    end

    // =============================================
    // 测试用例2：空消息测试
    // =============================================
    // $display("\n[TEST CASE 2] Testing empty message");

    // // 重新初始化
    // #20;
    // rst_n = 0;
    // data_in = 0;
    // data_in_valid = 0;
    // data_last = 0;
    // #10;

    // // 释放复位
    // rst_n = 1;
    // #10;

    // // 等待模块就绪
    // wait (data_ready);
    // @(posedge clk);

    // // 发送空消息 (仅last信号)
    // data_in_valid = 0;
    // data_last = 1;
    // @(posedge clk);
    // data_last = 0;

    // // 等待哈希输出
    // wait (hash_out_valid);
    // #0.1;

    // // 显示结果
    // $display("\nFinal hash:");
    // $display("%h %h %h %h", hash_out[255:224], hash_out[223:192], hash_out[191:160],
    //          hash_out[159:128]);
    // $display("%h %h %h %h", hash_out[127:96], hash_out[95:64], hash_out[63:32], hash_out[31:0]);

    // // 验证结果 (标准SHA-256("")结果)
    // if (hash_out === 256'he3b0c442_98fc1c14_9afbf4c8_996fb924_27ae41e4_649b934c_a495991b_7852b855) begin
    //   $display("[RESULT] PASS: Hash matches expected value for empty message");
    // end else begin
    //   $display("[RESULT] FAIL: Hash mismatch for empty message");
    //   $display("Expected: e3b0c442_98fc1c14_9afbf4c8_996fb924_27ae41e4_649b934c_a495991b_7852b855");
    //   $display("Received: %h", hash_out);
    // end

    // =============================================
    // 测试用例3：长消息测试 (56字节，需要两个块)
    // =============================================
    // $display("\n[TEST CASE 3] Testing long message (56 bytes)");

    // // 准备长测试消息 (56字节)
    // for (i = 0; i < 56; i = i + 1) begin
    //   test_message[i] = i + 8'h41;  // A, B, C, ..., etc.
    // end
    // message_length = 56;

    // // 重新初始化
    // #20;
    // rst_n = 0;
    // data_in = 0;
    // data_in_valid = 0;
    // data_last = 0;
    // #10;

    // // 释放复位
    // rst_n = 1;
    // #10;

    // // 等待模块就绪
    // wait (data_ready);
    // @(posedge clk);

    // // 发送长消息
    // for (i = 0; i < message_length; i = i + 1) begin
    //   data_in = test_message[i];
    //   data_in_valid = 1;
    //   data_last = (i == message_length - 1);
    //   @(posedge clk);
    // end

    // // 结束输入
    // data_in_valid = 0;
    // data_last = 0;

    // // 等待哈希输出
    // wait (hash_out_valid);
    // #0.1;

    // // 显示结果
    // $display("\nFinal hash:");
    // $display("%h %h %h %h", hash_out[255:224], hash_out[223:192], hash_out[191:160],
    //          hash_out[159:128]);
    // $display("%h %h %h %h", hash_out[127:96], hash_out[95:64], hash_out[63:32], hash_out[31:0]);

    // =============================================
    // 测试用例4：背压测试 (data_ready信号)
    // =============================================
    // $display("\n[TEST CASE 4] Testing backpressure (data_ready signal)");

    // // 准备测试消息
    // test_message[0] = "t";
    // test_message[1] = "e";
    // test_message[2] = "s";
    // test_message[3] = "t";
    // message_length  = 4;

    // // 重新初始化
    // #20;
    // rst_n = 0;
    // data_in = 0;
    // data_in_valid = 0;
    // data_last = 0;
    // #10;

    // // 释放复位
    // rst_n = 1;
    // #10;

    // // 测试背压
    // for (i = 0; i < message_length; i = i + 1) begin
    //   // 等待模块就绪
    //   while (!data_ready) @(posedge clk);

    //   // 发送数据
    //   data_in = test_message[i];
    //   data_in_valid = 1;
    //   data_last = (i == message_length - 1);
    //   @(posedge clk);
    // end

    // // 结束输入
    // data_in_valid = 0;
    // data_last = 0;

    // // 等待哈希输出
    // wait (hash_out_valid);
    // #0.1;

    // $display("[RESULT] PASS: Backpressure test completed");

    // =============================================
    // 结束仿真
    // =============================================
    #100;
    $display("\n[SIMULATION FINISHED]");
    $finish;
  end

  // 波形转储
  initial begin
    $dumpfile("top.vcd");
    $dumpvars(0, top_tb);
  end

endmodule
