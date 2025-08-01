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
    // 测试用例1：基本功能测试 - "abc"消息
    // =============================================
    $display("\n[TEST CASE 1] Testing 'abc' message (standard test vector)");

    // 测试用例1: "abc"消息 (标准SHA-256测试向量)
    test_message[0] = "a";
    test_message[1] = "b";
    test_message[2] = "c";
    message_length  = 3;

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
    $display("Final hash:");
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
    $display("\n[TEST CASE 2] Testing empty message");

    // 重新初始化
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

    // 发送空消息 (仅last信号)
    data_in_valid = 0;
    data_last = 1;
    @(posedge clk);
    data_last = 0;

    // 等待哈希输出
    wait (hash_out_valid);
    #0.1;

    // 显示结果
    $display("Final hash:");
    $display("%h %h %h %h", hash_out[255:224], hash_out[223:192], hash_out[191:160],
             hash_out[159:128]);
    $display("%h %h %h %h", hash_out[127:96], hash_out[95:64], hash_out[63:32], hash_out[31:0]);

    // 验证结果 (标准SHA-256("")结果)
    if (hash_out === 256'he3b0c442_98fc1c14_9afbf4c8_996fb924_27ae41e4_649b934c_a495991b_7852b855) begin
      $display("[RESULT] PASS: Hash matches expected value for empty message");
    end else begin
      $display("[RESULT] FAIL: Hash mismatch for empty message");
      $display("Expected: e3b0c442_98fc1c14_9afbf4c8_996fb924_27ae41e4_649b934c_a495991b_7852b855");
      $display("Received: %h", hash_out);
    end

    // =============================================
    // 测试用例3：基本功能测试 - "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"消息
    // =============================================
    $display(
        "\n[TEST CASE 3] Testing 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq' message (standard test vector)");

    // 测试用例3："abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"消息
    test_message[0]  = "a";
    test_message[1]  = "b";
    test_message[2]  = "c";
    test_message[3]  = "d";
    test_message[4]  = "b";
    test_message[5]  = "c";
    test_message[6]  = "d";
    test_message[7]  = "e";
    test_message[8]  = "c";
    test_message[9]  = "d";
    test_message[10] = "e";
    test_message[11] = "f";
    test_message[12] = "d";
    test_message[13] = "e";
    test_message[14] = "f";
    test_message[15] = "g";
    test_message[16] = "e";
    test_message[17] = "f";
    test_message[18] = "g";
    test_message[19] = "h";
    test_message[20] = "f";
    test_message[21] = "g";
    test_message[22] = "h";
    test_message[23] = "i";
    test_message[24] = "g";
    test_message[25] = "h";
    test_message[26] = "i";
    test_message[27] = "j";
    test_message[28] = "h";
    test_message[29] = "i";
    test_message[30] = "j";
    test_message[31] = "k";
    test_message[32] = "i";
    test_message[33] = "j";
    test_message[34] = "k";
    test_message[35] = "l";
    test_message[36] = "j";
    test_message[37] = "k";
    test_message[38] = "l";
    test_message[39] = "m";
    test_message[40] = "k";
    test_message[41] = "l";
    test_message[42] = "m";
    test_message[43] = "n";
    test_message[44] = "l";
    test_message[45] = "m";
    test_message[46] = "n";
    test_message[47] = "o";
    test_message[48] = "m";
    test_message[49] = "n";
    test_message[50] = "o";
    test_message[51] = "p";
    test_message[52] = "n";
    test_message[53] = "o";
    test_message[54] = "p";
    test_message[55] = "q";
    message_length   = 56;

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

    // 等待哈希输出————验证第二个哈希输出
    wait (hash_out_valid);
    @(negedge hash_out_valid);
    wait (hash_out_valid);
    #0.1;

    // 显示结果
    $display("Final hash:");
    $display("%h %h %h %h", hash_out[255:224], hash_out[223:192], hash_out[191:160],
             hash_out[159:128]);
    $display("%h %h %h %h", hash_out[127:96], hash_out[95:64], hash_out[63:32], hash_out[31:0]);

    // 验证结果
    if (hash_out === 256'h248d6a61_d20638b8_e5c02693_0c3e6039_a33ce459_64ff2167_f6ecedd4_19db06c1) begin
      $display(
          "[RESULT] PASS: Hash matches expected value for 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'");
    end else begin
      $display(
          "[RESULT] FAIL: Hash mismatch for 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'");
      $display("Expected: 248d6a61_d20638b8_e5c02693_0c3e6039_a33ce459_64ff2167_f6ecedd4_19db06c1");
      $display("Received: %h", hash_out);
    end

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
