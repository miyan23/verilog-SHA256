/*
 * 模块名称：sha256_round_middle
 *
 * 功能描述：
 *   本模块实现SHA-256算法中间16~31轮的双轮并行处理，每拍处理两轮。
 *
 * 主要特点：
 *   1. 双轮并行处理
 *   2. 使用消息扩展模块生成两个连续的Wt
 *   3. 使用单轮哈希计算模块计算两次哈希
 *
 * 接口说明：
 *   输入：
 *     - clk            ：时钟信号
 *     - rst_n          ：异步复位，低有效
 *     - round          ：当前轮次
 *     - block_in       ：输入消息块
 *     - hash_middle_in ：中间哈希值
 *   输出：
 *     - round_next      ：下两轮次
 *     - block_out       ：输出消息块（含扩展后的Wt）
 *     - hash_middle_out ：输出中间哈希值
 */

module sha256_round_middle (
    input wire clk,
    input wire rst_n,
    input wire [5:0] round,
    input wire [511:0] block_in,
    input wire [255:0] hash_middle_in,

    output reg [  5:0] round_next,
    output reg [511:0] block_out,
    output reg [255:0] hash_middle_out
);

  wire [5:0] round_plus1;
  wire [31:0] k_t1, k_t2;
  wire [31:0] w_t1, w_t2;
  wire [511:0] block_temp;
  wire [255:0] hash_middle_temp1, hash_middle_temp2;

  assign round_plus1 = round + 6'd1;
  assign block_temp  = {block_in[479:0], w_t1};

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      round_next <= 6'd0;
      block_out <= 512'b0;
      hash_middle_out <= 256'b0;
    end else begin
      round_next <= round + 6'd2;
      block_out <= {block_in[447:0], w_t1, w_t2};
      hash_middle_out <= hash_middle_temp2;
    end
  end

  sha256_calculate_k u_middle_k1 (
      .round(round),
      .K(k_t1)
  );

  sha256_calculate_k u_middle_k2 (
      .round(round_plus1),
      .K(k_t2)
  );

  sha256_calculate_w u_middle_w1 (
      .block_w(block_in),
      .w_t(w_t1)
  );

  sha256_calculate_w u_middle_w2 (
      .block_w(block_temp),
      .w_t(w_t2)
  );

  sha256_calculate_h u_middle_h1 (
      .hash_middle_in(hash_middle_in),
      .k_t(k_t1),
      .w_t(w_t1),
      .hash_middle_out(hash_middle_temp1)
  );

  sha256_calculate_h u_middle_h2 (
      .hash_middle_in(hash_middle_temp1),
      .k_t(k_t2),
      .w_t(w_t2),
      .hash_middle_out(hash_middle_temp2)
  );

endmodule
