/*
 * 模块名称：sha256_top
 * 
 * 功能描述：
 *   本模块是SHA-256算法的顶层集成模块，包含消息填充、消息扩展和压缩三个主要部分。
 *   支持任意长度消息输入，输出256位哈希值。
 *
 * 接口说明：
 *   - 输入为字节流形式，支持连续输入
 *   - 输出为完整的256位哈希值
 *   - 新增字节流输出接口，用于逐字节输出哈希值
 */

module sha256_top (
    input       clk,
    input       rst_n,
    input [7:0] data_in,        // 输入消息字节
    input       data_in_valid,  // 输入消息有效信号
    input       data_last,      // 输入消息最后一个字节标志

    output           data_ready,       // 模块就绪信号
    output reg       hash_out_valid,   // 哈希输出有效信号
    output reg       hash_byte_valid,  // 字节流输出有效信号
    output reg       hash_byte_last,   // 字节输出结束信号
    output reg [7:0] hash_byte_out     // 哈希值字节流输出
);

  // =============================================
  // 内部信号定义
  // =============================================
  // 填充模块信号
  wire [511:0] padded_block;
  wire         padded_block_valid;

  // 扩展模块信号
  wire [ 31:0] Wt;
  wire         Wt_valid;

  // 压缩模块信号
  wire [255:0] compressed_hash;
  wire         compressed_hash_valid;

  // 中间哈希值寄存器
  reg  [255:0] intermediate_hash;

  // 字节输出控制信号
  reg  [  5:0] byte_counter;  // 字节计数器(0-31)
  reg          byte_output_active;  // 字节输出激活标志

  // 初始哈希值常量（SHA-256初始值）
  parameter [255:0] INITIAL_HASH = {
    32'h6a09e667,
    32'hbb67ae85,
    32'h3c6ef372,
    32'ha54ff53a,
    32'h510e527f,
    32'h9b05688c,
    32'h1f83d9ab,
    32'h5be0cd19
  };

  // =============================================
  // 模块实例化
  // =============================================

  // 消息填充模块实例化
  sha256_padding padding_inst (
      .clk           (clk),
      .rst_n         (rst_n),
      .data_in       (data_in),
      .data_in_valid (data_in_valid),
      .data_last     (data_last),
      .data_out      (padded_block),
      .data_out_valid(padded_block_valid),
      .data_ready    (data_ready)
  );

  // 消息扩展模块实例化
  sha256_expand expand_inst (
      .clk        (clk),
      .rst_n      (rst_n),
      .block_in   (padded_block),
      .block_valid(padded_block_valid),
      .Wt_out     (Wt),
      .Wt_valid   (Wt_valid)
  );

  // 压缩模块实例化
  sha256_compress compress_inst (
      .clk           (clk),
      .rst_n         (rst_n),
      .Wt_in         (Wt),
      .Wt_valid      (Wt_valid),
      .hash_in       (intermediate_hash),
      .hash_out      (compressed_hash),
      .hash_out_valid(compressed_hash_valid)
  );

  // =============================================
  // 控制逻辑
  // =============================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位逻辑
      intermediate_hash  <= INITIAL_HASH;
      hash_out_valid     <= 0;
      hash_byte_out      <= 0;
      hash_byte_valid    <= 0;
      hash_byte_last     <= 0;
      byte_counter       <= 0;
      byte_output_active <= 0;

    end else begin
      hash_out_valid  <= 0;
      hash_byte_valid <= 0;
      hash_byte_last  <= 0;

      // 更新中间哈希值
      if (compressed_hash_valid) begin
        intermediate_hash <= compressed_hash;
        hash_out_valid <= 1;
      end

      if (hash_out_valid) begin
        byte_output_active <= 1;
        byte_counter <= 0;
      end

      // 字节流输出控制
      if (byte_output_active) begin
        if (byte_counter < 32) begin

          // 选择下一个字节输出 (大端序)
          case (byte_counter)
            0:  hash_byte_out <= intermediate_hash[255:248];
            1:  hash_byte_out <= intermediate_hash[247:240];
            2:  hash_byte_out <= intermediate_hash[239:232];
            3:  hash_byte_out <= intermediate_hash[231:224];
            4:  hash_byte_out <= intermediate_hash[223:216];
            5:  hash_byte_out <= intermediate_hash[215:208];
            6:  hash_byte_out <= intermediate_hash[207:200];
            7:  hash_byte_out <= intermediate_hash[199:192];
            8:  hash_byte_out <= intermediate_hash[191:184];
            9:  hash_byte_out <= intermediate_hash[183:176];
            10: hash_byte_out <= intermediate_hash[175:168];
            11: hash_byte_out <= intermediate_hash[167:160];
            12: hash_byte_out <= intermediate_hash[159:152];
            13: hash_byte_out <= intermediate_hash[151:144];
            14: hash_byte_out <= intermediate_hash[143:136];
            15: hash_byte_out <= intermediate_hash[135:128];
            16: hash_byte_out <= intermediate_hash[127:120];
            17: hash_byte_out <= intermediate_hash[119:112];
            18: hash_byte_out <= intermediate_hash[111:104];
            19: hash_byte_out <= intermediate_hash[103:96];
            20: hash_byte_out <= intermediate_hash[95:88];
            21: hash_byte_out <= intermediate_hash[87:80];
            22: hash_byte_out <= intermediate_hash[79:72];
            23: hash_byte_out <= intermediate_hash[71:64];
            24: hash_byte_out <= intermediate_hash[63:56];
            25: hash_byte_out <= intermediate_hash[55:48];
            26: hash_byte_out <= intermediate_hash[47:40];
            27: hash_byte_out <= intermediate_hash[39:32];
            28: hash_byte_out <= intermediate_hash[31:24];
            29: hash_byte_out <= intermediate_hash[23:16];
            30: hash_byte_out <= intermediate_hash[15:8];
            31: hash_byte_out <= intermediate_hash[7:0];
          endcase
          hash_byte_valid <= 1;
          byte_counter <= byte_counter + 6'd1;

        end else if (byte_counter == 32) begin
          // 32字节输出完成
          byte_output_active <= 0;
          byte_counter <= 0;
          hash_byte_last <= 1;
        end
      end
    end
  end

endmodule
