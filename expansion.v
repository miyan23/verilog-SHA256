/*
 * 模块名称：expansion
 *
 * 功能描述：
 *   本模块用于对输入的512位消息块进行SHA-256算法所需的消息扩展。
 *   采用16级流水线结构，每周期输出一个扩展后的消息字Wt。
 *
 * 扩展规则：
 *   1. 前16个字直接取自输入消息块
 *   2. 后48个字通过扩展算法生成：Wt = σ1(Wt-2) + Wt-7 + σ0(Wt-15) + Wt-16
 */

module expansion (
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
  reg [31:0] W                                     [0:63];  // 消息调度数组
  reg [31:0] stage_reg                             [0:15];  // 16级流水线寄存器
  reg [ 5:0] t_counter;  // 扩展计数器 (0-63)
  reg        active;  // 扩展过程激活标志

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
      for (int i = 0; i < 64; i++) W[i] <= 0;
      for (int i = 0; i < 16; i++) stage_reg[i] <= 0;
      t_counter <= 0;
      active <= 0;
      Wt_out <= 0;
      Wt_valid <= 0;
    end else begin
      // 默认输出无效
      Wt_valid <= 0;

      if (block_valid && !active) begin
        // 新块到达，初始化前16个字
        for (int t = 0; t < 16; t++) begin
          W[t] <= block_in[511-32*t-:32];
        end
        t_counter <= 16;  // 从第16个字开始扩展
        active <= 1;
        Wt_out <= W[0];  // 输出第一个字
        Wt_valid <= 1;
      end else if (active) begin
        // 扩展处理阶段
        if (t_counter < 64) begin
          // 计算新的Wt
          W[t_counter] <= sigma1(
              W[t_counter-2]
          ) + W[t_counter-7] + sigma0(
              W[t_counter-15]
          ) + W[t_counter-16];

          // 更新流水线寄存器
          for (int i = 0; i < 15; i++) begin
            stage_reg[i] <= stage_reg[i+1];
          end
          stage_reg[15] <= W[t_counter-16];  // 延迟16周期

          // 输出当前Wt (延迟16周期)
          Wt_out <= stage_reg[0];
          Wt_valid <= 1;

          t_counter <= t_counter + 1;
        end else begin
          // 扩展完成
          active   <= 0;
          Wt_valid <= 0;
        end
      end
    end
  end

endmodule
