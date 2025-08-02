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
 */

module sha256_top (
    input              clk,
    input              rst_n,
    input      [  7:0] data_in,         // 输入消息字节
    input              data_in_valid,   // 输入消息有效信号
    input              data_last,       // 输入消息最后一个字节标志
    output reg [255:0] hash_out,        // 输出哈希值
    output reg         hash_out_valid,  // 哈希输出有效信号
    output             data_ready       // 模块就绪信号（可接收新输入）
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

  // 有效信号流水线寄存器（用于同步）
  reg [1:0] valid_pipeline;

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
      intermediate_hash <= INITIAL_HASH;
      hash_out          <= 0;
      hash_out_valid    <= 0;
      valid_pipeline    <= 0;
    end else begin
      // 更新中间哈希值
      if (compressed_hash_valid) begin
        intermediate_hash <= compressed_hash;
      end

      // 输出哈希值（当最后一个块处理完成时）
      if (compressed_hash_valid && !padded_block_valid) begin
        hash_out <= compressed_hash;
      end

      // 有效信号流水线
      valid_pipeline <= {valid_pipeline[0], compressed_hash_valid};

      // 哈希输出有效信号（延迟一个周期）
      hash_out_valid <= valid_pipeline[1];
    end
  end

endmodule
