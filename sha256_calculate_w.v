/*
 * 模块名称：sha256_calculate_w
 *
 * 功能描述：
 *   本模块实现SHA-256算法中消息扩展功能，根据前16个消息字生成后续的Wt值。
 *
 * 主要特点：
 *   1. 组合逻辑实现，无时钟延迟
 *   2. 支持sigma0和sigma1函数计算
 *
 * 接口说明：
 *   输入：
 *     - block_w：当前块的消息字（512位）
 *   输出：
 *     - w_t：扩展后的消息字Wt（32位）
 */

module sha256_calculate_w (
    input wire [511:0] block_w,

    output wire [31:0] w_t
);

  wire [31:0] w_t_minus_2 = block_w[63:32];
  wire [31:0] w_t_minus_7 = block_w[223:192];
  wire [31:0] w_t_minus_15 = block_w[479:448];
  wire [31:0] w_t_minus_16 = block_w[511:480];

  assign w_t = sigma1(w_t_minus_2) + w_t_minus_7 + sigma0(w_t_minus_15) + w_t_minus_16;

  function [31:0] sigma0;
    input [31:0] x;

    begin
      sigma0 = {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ (x >> 3);
    end
  endfunction

  function [31:0] sigma1;
    input [31:0] x;

    begin
      sigma1 = {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ (x >> 10);
    end
  endfunction

endmodule
