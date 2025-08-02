`timescale 1ns / 1ps

module tb_sha256_top ();

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
  reg     [  7:0] test_message                     [0:511];  // 测试消息存储
  integer         message_length;  // 消息长度
  integer         i;  // 循环计数器

  // 实例化被测模块
  sha256_top uut (
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
      $display("[RESULT] PASS");
    end else begin
      $display("[RESULT] FAIL");
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
      $display("[RESULT] PASS");
    end else begin
      $display("[RESULT] FAIL");
      $display("Expected: e3b0c442_98fc1c14_9afbf4c8_996fb924_27ae41e4_649b934c_a495991b_7852b855");
      $display("Received: %h", hash_out);
    end

    // =============================================
    // 测试用例3：基本功能测试448 bits - "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"消息
    // =============================================
    $display(
        "\n[TEST CASE 3] Testing 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq' message (448 bits)");

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
      $display("[RESULT] PASS");
    end else begin
      $display("[RESULT] FAIL");
      $display("Expected: 248d6a61_d20638b8_e5c02693_0c3e6039_a33ce459_64ff2167_f6ecedd4_19db06c1");
      $display("Received: %h", hash_out);
    end

    // =============================================
    // 测试用例4：基本功能测试896 bits - "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"消息
    // =============================================
    $display(
        "\n[TEST CASE 4] Testing 'abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu' message (896 bits)");

    // 测试用例4："abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"消息
    test_message[0] = "a";
    test_message[1] = "b";
    test_message[2] = "c";
    test_message[3] = "d";
    test_message[4] = "e";
    test_message[5] = "f";
    test_message[6] = "g";
    test_message[7] = "h";
    test_message[8] = "b";
    test_message[9] = "c";
    test_message[10] = "d";
    test_message[11] = "e";
    test_message[12] = "f";
    test_message[13] = "g";
    test_message[14] = "h";
    test_message[15] = "i";
    test_message[16] = "c";
    test_message[17] = "d";
    test_message[18] = "e";
    test_message[19] = "f";
    test_message[20] = "g";
    test_message[21] = "h";
    test_message[22] = "i";
    test_message[23] = "j";
    test_message[24] = "d";
    test_message[25] = "e";
    test_message[26] = "f";
    test_message[27] = "g";
    test_message[28] = "h";
    test_message[29] = "i";
    test_message[30] = "j";
    test_message[31] = "k";
    test_message[32] = "e";
    test_message[33] = "f";
    test_message[34] = "g";
    test_message[35] = "h";
    test_message[36] = "i";
    test_message[37] = "j";
    test_message[38] = "k";
    test_message[39] = "l";
    test_message[40] = "f";
    test_message[41] = "g";
    test_message[42] = "h";
    test_message[43] = "i";
    test_message[44] = "j";
    test_message[45] = "k";
    test_message[46] = "l";
    test_message[47] = "m";
    test_message[48] = "g";
    test_message[49] = "h";
    test_message[50] = "i";
    test_message[51] = "j";
    test_message[52] = "k";
    test_message[53] = "l";
    test_message[54] = "m";
    test_message[55] = "n";
    test_message[56] = "h";
    test_message[57] = "i";
    test_message[58] = "j";
    test_message[59] = "k";
    test_message[60] = "l";
    test_message[61] = "m";
    test_message[62] = "n";
    test_message[63] = "o";
    test_message[64] = "i";
    test_message[65] = "j";
    test_message[66] = "k";
    test_message[67] = "l";
    test_message[68] = "m";
    test_message[69] = "n";
    test_message[70] = "o";
    test_message[71] = "p";
    test_message[72] = "j";
    test_message[73] = "k";
    test_message[74] = "l";
    test_message[75] = "m";
    test_message[76] = "n";
    test_message[77] = "o";
    test_message[78] = "p";
    test_message[79] = "q";
    test_message[80] = "k";
    test_message[81] = "l";
    test_message[82] = "m";
    test_message[83] = "n";
    test_message[84] = "o";
    test_message[85] = "p";
    test_message[86] = "q";
    test_message[87] = "r";
    test_message[88] = "l";
    test_message[89] = "m";
    test_message[90] = "n";
    test_message[91] = "o";
    test_message[92] = "p";
    test_message[93] = "q";
    test_message[94] = "r";
    test_message[95] = "s";
    test_message[96] = "m";
    test_message[97] = "n";
    test_message[98] = "o";
    test_message[99] = "p";
    test_message[100] = "q";
    test_message[101] = "r";
    test_message[102] = "s";
    test_message[103] = "t";
    test_message[104] = "n";
    test_message[105] = "o";
    test_message[106] = "p";
    test_message[107] = "q";
    test_message[108] = "r";
    test_message[109] = "s";
    test_message[110] = "t";
    test_message[111] = "u";
    message_length = 112;

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
    if (hash_out === 256'hcf5b16a7_78af8380_036ce59e_7b049237_0b249b11_e8f07a51_afac4503_7afee9d1) begin
      $display("[RESULT] PASS");
    end else begin
      $display("[RESULT] FAIL");
      $display("Expected: cf5b16a7_78af8380_036ce59e_7b049237_0b249b11_e8f07a51_afac4503_7afee9d1");
      $display("Received: %h", hash_out);
    end

    // =============================================
    // 测试用例5：基本功能测试1000 bytes - "a"*1000消息
    // =============================================
    $display("\n[TEST CASE 5] Testing 'a'*1000 message (1000 bytes)");

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
    for (i = 0; i < 1000; i = i + 1) begin
      data_in = "a";
      data_in_valid = 1;
      data_last = (i == 1000 - 1);
      @(posedge clk);
    end

    // 结束输入
    data_in_valid = 0;
    data_last = 0;

    // 等待哈希输出————验证第十六个哈希输出
    wait (hash_out_valid);
    @(negedge hash_out_valid);
    wait (hash_out_valid);
    @(negedge hash_out_valid);
    wait (hash_out_valid);
    @(negedge hash_out_valid);
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
    if (hash_out === 256'h41edece4_2d63e8d9_bf515a9b_a6932e1c_20cbc9f5_a5d13464_5adb5db1_b9737ea3) begin
      $display("[RESULT] PASS");
    end else begin
      $display("[RESULT] FAIL");
      $display("Expected: 41edece4_2d63e8d9_bf515a9b_a6932e1c_20cbc9f5_a5d13464_5adb5db1_b9737ea3");
      $display("Received: %h", hash_out);
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
    $dumpfile("tb_sha256_top.vcd");
    $dumpvars(0, tb_sha256_top);
  end

endmodule
