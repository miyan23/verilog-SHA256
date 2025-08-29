/*
 * 模块名称：sha256_round_final
 *
 * 功能描述：
 *   本模块实现SHA-256算法最后一轮（第63轮）的处理，并完成与初始哈希值的累加。
 *
 * 主要特点：
 *   1. 处理最后一轮哈希计算
 *   2. 完成与初始哈希值的累加
 *
 * 接口说明：
 *   输入：
 *     - clk            ：时钟信号
 *     - rst_n          ：异步复位，低有效
 *     - round          ：当前轮次（63）
 *     - block_in       ：输入消息块
 *     - hash_middle_in ：中间哈希值
 *     - initial_hash   ：初始哈希值
 *   输出：
 *     - final_round ：最终轮次（64）
 *     - final_block ：最终消息块
 *     - final_hash  ：最终哈希值
 */

module sha256_round_final (
    input wire clk,
    input wire rst_n,
    input wire [5:0] round,
    input wire [511:0] block_in,
    input wire [255:0] hash_middle_in,
    input wire [255:0] initial_hash,

    output reg [255:0] final_hash
);

  wire [ 31:0] k_t;
  wire [ 31:0] w_t;
  wire [255:0] hash_middle_temp;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      final_hash <= 256'b0;
    end else begin
      final_hash <= {
        hash_middle_temp[255:224] + initial_hash[255:224],
        hash_middle_temp[223:192] + initial_hash[223:192],
        hash_middle_temp[191:160] + initial_hash[191:160],
        hash_middle_temp[159:128] + initial_hash[159:128],
        hash_middle_temp[127:96] + initial_hash[127:96],
        hash_middle_temp[95:64] + initial_hash[95:64],
        hash_middle_temp[63:32] + initial_hash[63:32],
        hash_middle_temp[31:0] + initial_hash[31:0]
      };
    end
  end

  sha256_calculate_k u_final_k (
      .round(round),
      .K(k_t)
  );

  sha256_calculate_w u_final_w (
      .block_w(block_in),
      .w_t(w_t)
  );

  sha256_calculate_h u_final_h (
      .hash_middle_in(hash_middle_in),
      .k_t(k_t),
      .w_t(w_t),
      .hash_middle_out(hash_middle_temp)
  );

endmodule
