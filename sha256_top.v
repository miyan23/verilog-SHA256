/*
 * 模块名称：sha256_top
 *
 * 功能描述：
 *   本模块为SHA-256算法的顶层模块，支持多块连续处理，控制压缩模块的启动与暂停。
 *
 * 主要特点：
 *   1. 支持背靠背多块连续处理
 *   2. 自动管理中间哈希值的传递
 *   3. 支持单块和多块消息处理
 *   4. 当连续输入同一个消息的多个块时需要暂停，等每个块处理完之后再输入（因为第1级和第48级都要使用初始哈希值，此时连续输入会更新哈希值）
 *
 * 接口说明：
 *   输入：
 *     - clk      ：时钟信号
 *     - rst_n    ：异步复位，低有效
 *     - valid_in ：输入有效信号
 *     - is_last  ：是否为最后一块
 *     - block_in ：输入消息块（512位）
 *   输出：
 *     - pause    ：暂停信号
 *     - valid_out：输出有效信号
 *     - hash_out ：最终哈希值（256位）
 */

module sha256_top (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire is_last,
    input wire [511:0] block_in,

    output reg pause,
    output wire valid_out,
    output wire [255:0] hash_out
);

  localparam [255:0] INITIAL_HASH = {
    32'h6a09e667,
    32'hbb67ae85,
    32'h3c6ef372,
    32'ha54ff53a,
    32'h510e527f,
    32'h9b05688c,
    32'h1f83d9ab,
    32'h5be0cd19
  };

  reg [5:0] pause_cnt;
  reg [255:0] intermediate_hash;
  reg need_new_hash;
  wire [255:0] initial_hash;

  assign initial_hash = need_new_hash ? intermediate_hash : INITIAL_HASH;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pause <= 1'b0;
      pause_cnt <= 6'd0;
      need_new_hash <= 1'b0;
      intermediate_hash <= INITIAL_HASH;
    end else begin
      if (valid_in && !is_last) begin
        pause <= 1'b1;
        pause_cnt <= 6'd0;
      end else if (need_new_hash) begin
        pause <= 1'b1;
      end

      if (pause && pause_cnt < 6'd48) begin
        pause_cnt <= pause_cnt + 6'd1;
      end else if (pause_cnt == 6'd48 && valid_out) begin
        pause <= 1'b0;
        pause_cnt <= 6'd0;
        need_new_hash <= 1'b1;
      end

      if (valid_out && is_last) begin
        need_new_hash <= 1'b0;
        pause <= 1'b0;
      end

      if (valid_out) begin
        intermediate_hash <= hash_out;
      end
    end
  end

  sha256_compress u_compress (
      .clk(clk),
      .rst_n(rst_n),
      .block_in(block_in),
      .initial_hash(initial_hash),
      .start(valid_in),

      .final_hash(hash_out),
      .done(valid_out)
  );

endmodule
