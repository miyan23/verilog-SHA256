`timescale 1ns / 1ps

module padding_tb ();

  // 时钟和复位信号
  reg clk;
  reg rst_n;

  // 模块输入
  reg [7:0] data_in;
  reg data_in_valid;
  reg data_last;

  // 模块输出
  wire [511:0] data_out;
  wire data_out_valid;
  wire data_ready;

  // 实例化被测模块
  padding uut (
      .clk(clk),
      .rst_n(rst_n),
      .data_in(data_in),
      .data_in_valid(data_in_valid),
      .data_last(data_last),
      .data_out(data_out),
      .data_out_valid(data_out_valid),
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
    // 测试用例1：正常消息"abc"测试
    // =============================================
    $display("\n[TEST CASE 1] Testing normal message 'abc'");

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

    // 发送消息序列
    // 消息"a"
    data_in = "a";
    data_in_valid = 1;
    data_last = 0;
    @(posedge clk);

    // 消息"b"
    data_in = "b";
    @(posedge clk);

    // 消息"c"（最后一个字节）
    data_in   = "c";
    data_last = 1;
    @(posedge clk);

    // 结束输入
    data_in_valid = 0;
    data_last = 0;

    // 等待填充完成
    wait (data_out_valid);

    // 显示结果
    $display("\nPadded block (hexadecimal):");
    $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416],
             data_out[415:384]);
    $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288],
             data_out[287:256]);
    $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160],
             data_out[159:128]);
    $display("%h %h %h %h", data_out[127:96], data_out[95:64], data_out[63:32], data_out[31:0]);

    // 验证结果
    if (data_out === 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018) begin
      $display("[RESULT] PASS: Output matches expected pattern");
    end else begin
      $display("[RESULT] FAIL: Output mismatch");
      $display("Expected: 6162638000000000...00000018");
      $display("Received: %h", data_out);
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

    // 发送空消息（仅last信号）
    data_in_valid = 0;
    data_last = 1;
    @(posedge clk);
    data_last = 0;

    // 等待填充完成
    wait (data_out_valid);

    // 显示结果
    $display("\nPadded block (hexadecimal):");
    $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416],
             data_out[415:384]);
    $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288],
             data_out[287:256]);
    $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160],
             data_out[159:128]);
    $display("%h %h %h %h", data_out[127:96], data_out[95:64], data_out[63:32], data_out[31:0]);

    // 验证结果
    if (data_out === 512'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000) begin
      $display("[RESULT] PASS: Empty message padded correctly");
    end else begin
      $display("[RESULT] FAIL: Empty message padding error");
      $display("Expected: 80000000...00000000");
      $display("Received: %h", data_out);
    end

    // =============================================
    // 测试用例3：单字节消息测试
    // =============================================
    $display("\n[TEST CASE 3] Testing single byte message 'A'");

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

    // 发送单字节消息 "A"
    data_in = "A";
    data_in_valid = 1;
    data_last = 1;  // 标记为最后一个字节
    @(posedge clk);

    // 结束输入
    data_in_valid = 0;
    data_last = 0;

    // 等待填充完成
    wait (data_out_valid);

    // 显示结果
    $display("\nPadded block (hexadecimal):");
    $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416],
             data_out[415:384]);
    $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288],
             data_out[287:256]);
    $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160],
             data_out[159:128]);
    $display("%h %h %h %h", data_out[127:96], data_out[95:64], data_out[63:32], data_out[31:0]);

    // 验证结果 (单字节'A'=0x41, 长度8位)
    // 格式: 41 80 00...00 00000008
    if (data_out === 512'h41800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008) begin  // 长度字段 (8位)
      $display("[RESULT] PASS: Single byte message padded correctly");
    end else begin
      $display("[RESULT] FAIL: Single byte message padding error");
      $display("Expected: 41800000...00000008");
      $display("Received: %h", data_out);
      $display("Message byte: %h", data_out[511:504]);
      $display("Length field: %h", data_out[63:0]);
    end

    // =============================================
    // 测试用例4：55字节消息测试 (正好填充一个块)
    // =============================================
    $display("\n[TEST CASE 4] Testing 55-byte message");

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

    // 发送55字节消息 (全部发送0xAA作为测试数据)
    for (integer i = 0; i < 55; i = i + 1) begin
      data_in = 8'hAA;  // 测试数据
      data_in_valid = 1;
      data_last = (i == 54);  // 最后一个字节设置msg_last
      @(posedge clk);
    end

    // 结束输入
    data_in_valid = 0;
    data_last = 0;

    // 等待填充完成
    wait (data_out_valid);

    // 显示填充结果
    $display("\nPadded block (hexadecimal):");
    $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416],
             data_out[415:384]);
    $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288],
             data_out[287:256]);
    $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160],
             data_out[159:128]);
    $display("%h %h %h %h", data_out[127:96], data_out[95:64], data_out[63:32], data_out[31:0]);

    // 验证结果
    // 格式: 预期格式：55个AA + 80 + 7个00 + 64位长度(0x00000000000001B8)
    if (data_out === 512'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa8000000000000001b8) begin  // 长度字段 (8位)
      $display("[RESULT] PASS: 55-byte message padded correctly in one block");
    end else begin
      $display("[RESULT] FAIL: Padding error");
      $display("Expected: 55*AA + 80 + 7*00 + 00000000000001B8");
      $display("Received: %h", data_out);
    end

    // =============================================
    // 测试用例5：448比特-56字节消息测试 (刚好一个块不够)
    // =============================================
    $display("\n[TEST CASE 5] Testing 448-bit message");

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

    // 发送448比特（56字节）消息（abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq）
    data_in = "a";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "b";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "c";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "d";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "b";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "c";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "d";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "e";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "c";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "d";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "e";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "f";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "d";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "e";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "f";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "g";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "e";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "f";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "g";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "h";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "f";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "g";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "h";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "i";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "g";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "h";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "i";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "j";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "h";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "i";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "j";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "k";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "i";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "j";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "k";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "l";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "j";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "k";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "l";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "m";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "k";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "l";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "m";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "n";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "l";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "m";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "n";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "o";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "m";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "n";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "o";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "p";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "n";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "o";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "p";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "q";
    data_in_valid = 1;
    data_last = 1;
    @(posedge clk);

    // 结束输入
    data_in_valid = 0;
    data_last = 0;

    // 验证第一个块
    wait (data_out_valid);
    if (data_out === 512'h6162636462636465636465666465666765666768666768696768696a68696a6b696a6b6c6a6b6c6d6b6c6d6e6c6d6e6f6d6e6f706e6f70718000000000000000) begin
      $display("\nPadded block:");
      $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416],
               data_out[415:384]);
      $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288],
               data_out[287:256]);
      $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160],
               data_out[159:128]);
      $display("%h %h %h %h", data_out[127:96], data_out[95:64], data_out[63:32], data_out[31:0]);

      $display("[RESULT] PASS: 56-byte message padded correctly in first block");
    end else begin
      $display("[RESULT] FAIL: Padding error");
      $display(
          "Expected: 6162636462636465636465666465666765666768666768696768696a68696a6b696a6b6c6a6b6c6d6b6c6d6e6c6d6e6f6d6e6f706e6f70718000000000000000");
      $display("Received: %h", data_out);
    end

    // 验证第二个块
    @(negedge data_out_valid);
    wait (data_out_valid);
    if (data_out === 512'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c0) begin
      $display("\nPadded block:");
      $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416],
               data_out[415:384]);
      $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288],
               data_out[287:256]);
      $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160],
               data_out[159:128]);
      $display("%h %h %h %h", data_out[127:96], data_out[95:64], data_out[63:32], data_out[31:0]);

      $display("[RESULT] PASS: 56-byte message padded correctly in second block");
    end else begin
      $display("[RESULT] FAIL: Padding error");
      $display(
          "Expected: 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c0");
      $display("Received: %h", data_out);
    end

    // =============================================
    // 测试用例6：896bit消息测试 (需要两个块)
    // =============================================
    $display("\n[TEST CASE 6] Testing 896-bit message");

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

    // 发送896比特（112字节）消息（abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu）
    data_in = "a";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "b";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "c";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "d";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "e";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "f";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "g";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "h";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "b";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "c";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "d";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "e";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "f";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "g";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "h";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "i";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "c";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "d";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "e";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "f";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "g";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "h";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "i";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "j";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "d";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "e";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "f";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "g";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "h";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "i";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "j";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "k";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "e";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "f";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "g";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "h";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "i";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "j";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "k";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "l";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "f";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "g";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "h";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "i";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "j";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "k";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "l";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "m";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "g";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "h";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "i";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "j";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "k";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "l";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "m";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "n";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "h";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "i";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "j";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "k";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "l";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "m";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "n";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "o";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "i";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "j";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "k";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "l";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "m";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "n";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "o";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "p";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "j";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "k";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "l";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "m";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "n";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "o";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "p";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "q";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "k";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "l";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "m";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "n";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "o";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "p";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "q";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "r";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "l";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "m";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "n";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "o";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "p";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "q";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "r";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "s";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "m";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "n";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "o";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "p";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "q";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "r";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "s";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "t";
    data_in_valid = 1;
    @(posedge clk);

    data_in = "n";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "o";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "p";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "q";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "r";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "s";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "t";
    data_in_valid = 1;
    @(posedge clk);
    data_in = "u";
    data_in_valid = 1;
    data_last = 1;
    @(posedge clk);

    // 结束输入
    data_in_valid = 0;
    data_last = 0;

    // 验证第二个块
    wait (data_out_valid);
    if (data_out === 512'h696a6b6c6d6e6f706a6b6c6d6e6f70716b6c6d6e6f7071726c6d6e6f707172736d6e6f70717273746e6f70717273747580000000000000000000000000000380) begin
      $display("\nPadded block:");
      $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416],
               data_out[415:384]);
      $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288],
               data_out[287:256]);
      $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160],
               data_out[159:128]);
      $display("%h %h %h %h", data_out[127:96], data_out[95:64], data_out[63:32], data_out[31:0]);

      $display("[RESULT] PASS: 896-bit message padded correctly in second block");
    end else begin
      $display("[RESULT] FAIL: Padding error");
      $display(
          "Expected: 696a6b6c6d6e6f706a6b6c6d6e6f70716b6c6d6e6f7071726c6d6e6f707172736d6e6f70717273746e6f70717273747580000000000000000000000000000380");
      $display("Received: %h", data_out);
    end

    // =============================================
    // 测试用例7：1000字节消息测试 (需要十六块)
    // =============================================
    $display("\n[TEST CASE 7] Testing 1000-byte message");

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

    // 发送1000字节消息（"a"*1000）
    for (integer i = 0; i < 1000; i = i + 1) begin
      data_in = "a";
      data_in_valid = 1;
      data_last = (i == 999);
      @(posedge clk);
    end

    // 结束输入
    data_in_valid = 0;
    data_last = 0;

    // 验证第十六个块
    wait (data_out_valid);
    if (data_out === 512'h61616161616161616161616161616161616161616161616161616161616161616161616161616161800000000000000000000000000000000000000000001f40) begin
      $display("\nPadded block:");
      $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416],
               data_out[415:384]);
      $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288],
               data_out[287:256]);
      $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160],
               data_out[159:128]);
      $display("%h %h %h %h", data_out[127:96], data_out[95:64], data_out[63:32], data_out[31:0]);

      $display("[RESULT] PASS: 1000-byte message padded correctly in 16 block");
    end else begin
      $display("[RESULT] FAIL: Padding error");
      $display(
          "Expected: 61616161616161616161616161616161616161616161616161616161616161616161616161616161800000000000000000000000000000000000000000001f40");
      $display("Received: %h", data_out);
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
    $dumpfile("padding.vcd");
    $dumpvars(0, padding_tb);
  end

endmodule
