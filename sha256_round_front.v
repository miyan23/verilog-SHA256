/*
 * 模块名称：sha256_round_front
 *
 * 功能描述：
 *   本模块实现SHA-256算法前16轮的单轮处理，每拍处理一轮。
 *
 * 主要特点：
 *   1. 单轮处理，无消息扩展
 *   2. 直接使用输入块的高32位作为Wt，结束后输入块循环左移32位
 *   3. 16轮之后输入块正好还原
 *
 * 接口说明：
 *   输入：
 *     - clk            ：时钟信号
 *     - rst_n          ：异步复位，低有效
 *     - round          ：当前轮次
 *     - block_in       ：输入消息块
 *     - hash_middle_in ：中间哈希值
 *   输出：
 *     - round_next      ：下一轮次
 *     - block_out       ：输出消息块（循环移位）
 *     - hash_middle_out ：输出中间哈希值
 */

module sha256_round_front (
    input wire clk,
    input wire rst_n,
    input wire [5:0] round,
    input wire [511:0] block_in,
    input wire [255:0] hash_middle_in,

    output reg [  5:0] round_next,
    output reg [511:0] block_out,
    output reg [255:0] hash_middle_out
);

  wire [ 31:0] k_t;
  wire [ 31:0] w_t;
  wire [255:0] hash_middle_temp;

  assign w_t = block_in[511:480];

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      round_next <= 6'd0;
      block_out <= 512'b0;
      hash_middle_out <= 256'b0;
    end else begin
      round_next <= round + 6'd1;
      block_out <= {block_in[479:0], block_in[511:480]};
      hash_middle_out <= hash_middle_temp;
    end
  end

  sha256_calculate_k u_front_k (
      .round(round),
      .K(k_t)
  );

  sha256_calculate_h u_front_h (
      .hash_middle_in(hash_middle_in),
      .k_t(k_t),
      .w_t(w_t),
      .hash_middle_out(hash_middle_temp)
  );

endmodule
