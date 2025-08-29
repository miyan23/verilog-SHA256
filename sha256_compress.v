/*
 * 模块名称：sha256_compress
 *
 * 功能描述：
 *   本模块实现SHA-256算法的压缩函数，采用48级流水线结构处理64轮哈希计算。
 *
 * 主要特点：
 *   1. 48级流水线，支持高吞吐率
 *   2. 分为前16轮、中间16级（双轮并行）、后15轮和最终1轮
 *   3. 支持连续块处理
 *
 * 接口说明：
 *   输入：
 *     - clk         ：时钟信号
 *     - rst_n       ：异步复位，低有效
 *     - block_in    ：输入的消息块（512位）
 *     - initial_hash：初始哈希值（256位）
 *     - start       ：开始压缩信号
 *   输出：
 *     - final_hash：压缩后的哈希值（256位）
 *     - done      ：压缩完成信号
 */

module sha256_compress (
    input wire clk,
    input wire rst_n,
    input wire [511:0] block_in,
    input wire [255:0] initial_hash,
    input wire start,

    output wire [255:0] final_hash,
    output wire done
);

  reg [511:0] block_in_reg;
  reg [255:0] initial_hash_reg;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      block_in_reg <= 512'b0;
      initial_hash_reg <= 256'b0;
    end else begin
      if (start) begin
        block_in_reg <= block_in;
        initial_hash_reg <= initial_hash;
      end
    end
  end

  wire [  5:0] round_wire[0:47];
  wire [511:0] block_wire[0:47];
  wire [255:0] hash_wire [0:47];

  assign round_wire[0] = 6'd0;
  assign block_wire[0] = block_in_reg;
  assign hash_wire[0]  = initial_hash_reg;

  reg valid_reg[0:48];
  assign done = valid_reg[48];

  integer t;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (t = 0; t <= 48; t = t + 1) begin
        valid_reg[t] <= 1'b0;
      end
    end else begin
      valid_reg[0] <= start;
      for (t = 1; t <= 48; t = t + 1) begin
        valid_reg[t] <= valid_reg[t-1];
      end
    end
  end

  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : round_front
      sha256_round_front u_front (
          .clk(clk),
          .rst_n(rst_n),
          .round(round_wire[i]),
          .block_in(block_wire[i]),
          .hash_middle_in(hash_wire[i]),

          .round_next(round_wire[i+1]),
          .block_out(block_wire[i+1]),
          .hash_middle_out(hash_wire[i+1])
      );
    end
  endgenerate

  generate
    for (i = 16; i < 32; i = i + 1) begin : round_middle
      sha256_round_middle u_middle (
          .clk(clk),
          .rst_n(rst_n),
          .round(round_wire[i]),
          .block_in(block_wire[i]),
          .hash_middle_in(hash_wire[i]),

          .round_next(round_wire[i+1]),
          .block_out(block_wire[i+1]),
          .hash_middle_out(hash_wire[i+1])
      );
    end
  endgenerate

  generate
    for (i = 32; i < 47; i = i + 1) begin : round_back
      sha256_round_back u_back (
          .clk(clk),
          .rst_n(rst_n),
          .round(round_wire[i]),
          .block_in(block_wire[i]),
          .hash_middle_in(hash_wire[i]),

          .round_next(round_wire[i+1]),
          .block_out(block_wire[i+1]),
          .hash_middle_out(hash_wire[i+1])
      );
    end
  endgenerate

  sha256_round_final u_final (
      .clk(clk),
      .rst_n(rst_n),
      .round(round_wire[47]),
      .block_in(block_wire[47]),
      .hash_middle_in(hash_wire[47]),
      .initial_hash(initial_hash),

      .final_hash(final_hash)
  );

endmodule
