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
  wire ready;

  // 实例化被测模块
  padding uut (
      .clk(clk),
      .rst_n(rst_n),
      .data_in(data_in),
      .data_in_valid(data_in_valid),
      .data_last(data_last),
      .data_out(data_out),
      .data_out_valid(data_out_valid),
      .ready(ready)
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
    wait (ready);
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
    data_last  = 0;

    // 等待填充完成
    wait (data_out_valid);

    // 显示结果
    $display("\nPadded block (hexadecimal):");
    $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416], data_out[415:384]);
    $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288], data_out[287:256]);
    $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160], data_out[159:128]);
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
    wait (ready);
    @(posedge clk);

    // 发送空消息（仅last信号）
    data_in_valid = 0;
    data_last  = 1;
    @(posedge clk);
    data_last = 0;

    // 等待填充完成
    wait (data_out_valid);

    // 显示结果
    $display("\nPadded block (hexadecimal):");
    $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416], data_out[415:384]);
    $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288], data_out[287:256]);
    $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160], data_out[159:128]);
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
    wait (ready);
    @(posedge clk);

    // 发送单字节消息 "A"
    data_in = "A";
    data_in_valid = 1;
    data_last = 1;  // 标记为最后一个字节
    @(posedge clk);

    // 结束输入
    data_in_valid = 0;
    data_last  = 0;

    // 等待填充完成
    wait (data_out_valid);

    // 显示结果
    $display("\nPadded block (hexadecimal):");
    $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416], data_out[415:384]);
    $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288], data_out[287:256]);
    $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160], data_out[159:128]);
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
    wait (ready);
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
    data_last  = 0;

    // 等待填充完成
    wait (data_out_valid);

    // 显示填充结果
    $display("\nPadded block (hexadecimal):");
    $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416], data_out[415:384]);
    $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288], data_out[287:256]);
    $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160], data_out[159:128]);
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
    // 测试用例5：56字节消息测试 (需要两个块)
    // =============================================
    $display("\n[TEST CASE 5] Testing 56-byte message");

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
    wait (ready);
    @(posedge clk);

    // 发送56字节消息 (全部发送0xBB作为测试数据)
    for (integer i = 0; i < 56; i = i + 1) begin
      data_in = 8'hBB;  // 测试数据
      data_in_valid = 1;
      data_last = (i == 55);  // 最后一个字节设置msg_last
      @(posedge clk);
    end

    // 结束输入
    data_in_valid = 0;
    data_last  = 0;

    // 等待第一个填充块完成
    wait (data_out_valid);

    // 显示第一个填充块
    $display("\nFirst padded block (hexadecimal):");
    $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416], data_out[415:384]);
    $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288], data_out[287:256]);
    $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160], data_out[159:128]);
    $display("%h %h %h %h", data_out[127:96], data_out[95:64], data_out[63:32], data_out[31:0]);

    // 验证第一个块
    // 预期格式：56个BB + 80 + 7个00
    if (data_out === 512'hbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8000000000000000) begin
      $display("[RESULT] PASS: First block of 56-byte message padded correctly");
    end else begin
      $display("[RESULT] FAIL: First block padding error");
      $display("Expected: 56*BB + 80 + 7*00");
      $display("Received: %h", data_out);
    end

    // 等待第一个块的valid信号变低
    @(negedge data_out_valid);
    // 等待第二个填充块完成
    wait (data_out_valid);

    // 显示第二个填充块
    $display("\nSecond padded block (hexadecimal):");
    $display("%h %h %h %h", data_out[511:480], data_out[479:448], data_out[447:416], data_out[415:384]);
    $display("%h %h %h %h", data_out[383:352], data_out[351:320], data_out[319:288], data_out[287:256]);
    $display("%h %h %h %h", data_out[255:224], data_out[223:192], data_out[191:160], data_out[159:128]);
    $display("%h %h %h %h", data_out[127:96], data_out[95:64], data_out[63:32], data_out[31:0]);

    // 验证第二个块
    // 预期格式：448位0 + 64位长度(0x00000000000001C0)    
    if (data_out === 512'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c0) begin
      $display("[RESULT] PASS: Second block of 56-byte message padded correctly");
    end else begin
      $display("[RESULT] FAIL: Second block padding error");
      $display("Expected: all zeros + 00000000000001C0");
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
