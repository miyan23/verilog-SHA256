/*
 * 模块名称：expand
 *
 * 功能描述：
 *   本模块用于对输入的512位消息块进行SHA-256算法所需的消息扩展。
 *   采用16级流水线结构，每周期输出一个扩展后的消息字Wt。
 *   支持连续块处理，当第一个块正在处理时接收第二个块会先缓存。
 *
 * 扩展规则：
 *   1. 前16个字直接取自输入消息块
 *   2. 后48个字通过扩展算法生成：W[t] = σ1(W[t-2]) + W[t-7] + σ0(W[t-15]) + W[t-16]
 */

module expand (
    input              clk,
    input              rst_n,
    input      [511:0] block_in,     // 512-bit input message block
    input              block_valid,  // 输入块有效信号
    output reg [ 31:0] Wt_out,       // 当前级的Wt输出
    output reg         Wt_valid      // Wt输出有效信号
);

  // =============================================
  // 内部信号定义
  // =============================================
  reg [ 31:0] W                                           [0:63];  // 消息调度数组
  reg [ 31:0] pipeline_reg                                    [0:15];  // 16级流水线寄存器
  reg [  6:0] expand_counter;  // 扩展计数器 (0-63)
  reg         expand_active;  // 扩展过程激活标志
  reg [511:0] buffer_block;  // 输入块缓存
  reg         buffer_valid;  // 缓存有效标志

  // =============================================
  // σ0和σ1函数定义
  // =============================================
  function [31:0] sigma0;
    input [31:0] x;
    sigma0 = {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ (x >> 3);
  endfunction

  function [31:0] sigma1;
    input [31:0] x;
    sigma1 = {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ (x >> 10);
  endfunction

  // =============================================
  // 主处理逻辑
  // =============================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位所有寄存器
      for (integer i = 0; i < 64; i++) W[i] <= 0;
      for (integer i = 0; i < 16; i++) pipeline_reg[i] <= 0;
      expand_counter <= 0;
      expand_active  <= 0;
      Wt_out         <= 0;
      Wt_valid       <= 0;
      buffer_block   <= 0;
      buffer_valid   <= 0;

    end else begin
      // 默认输出无效
      Wt_valid <= 0;

      // ------------------------------
      // 输入块处理（含缓存逻辑）
      // ------------------------------
      if (block_valid) begin
        if (!expand_active) begin
          // 当前无处理块，直接处理新块
          for (integer t = 0; t < 16; t++) begin
            W[t]        <= block_in[511-32*t-:32];
            pipeline_reg[t] <= 32'hFFFFFFFF;
          end
          expand_counter <= 16;
          expand_active  <= 1;
        end else begin
          // 当前正处理块，缓存新块
          buffer_block <= block_in;
          buffer_valid <= 1;
        end
      end

      // ------------------------------
      // 扩展处理阶段
      // ------------------------------
      if (expand_active) begin
        if (expand_counter < 96) begin
          // 计算新的Wt
          if (expand_counter < 64) begin
            W[expand_counter] <= sigma1(W[expand_counter-2]) + W[expand_counter-7] +
                sigma0(W[expand_counter-15]) + W[expand_counter-16];
          end

          // 更新流水线寄存器
          for (integer i = 0; i < 15; i++) begin
            pipeline_reg[i] <= pipeline_reg[i+1];
          end

          if (expand_counter < 80) begin
            pipeline_reg[15] <= W[expand_counter-16];  // 延迟16周期
          end else begin
            pipeline_reg[15] <= 0;  // 超出范围时清零
          end

          // 输出当前Wt
          if (expand_counter >= 32) begin
            Wt_out   <= pipeline_reg[0];
            Wt_valid <= 1;
          end

          expand_counter <= expand_counter + 1;

        end else begin
          // 当前块扩展完成
          expand_active <= 0;
          Wt_valid      <= 0;

          // 检查并处理缓存块
          if (buffer_valid) begin
            for (integer t = 0; t < 16; t++) begin
              W[t]        <= buffer_block[511-32*t-:32];
              pipeline_reg[t] <= 32'hFFFFFFFF;
            end
            expand_counter <= 16;
            expand_active  <= 1;
            buffer_valid   <= 0;
          end
        end
      end
    end
  end

endmodule
