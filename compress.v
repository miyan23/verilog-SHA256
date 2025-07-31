/*
 * 模块名称：compress
 *
 * 功能描述：
 *   本模块实现SHA-256算法的压缩函数部分，采用32级流水线结构。
 *   输出最终的哈希值。
 *
 * 主要特点：
 *   1. 32级流水线处理64个Wt
 *   2. 完全同步设计，与扩展模块时钟对齐
 *   3. 支持连续块处理，保持高吞吐量
 */

module compress (
    input              clk,
    input              rst_n,
    input      [ 31:0] Wt_in,          // 来自消息扩展的Wt (Wt0-Wt63)
    input              Wt_valid,       // Wt输入有效信号
    input      [255:0] hash_in,        // 初始哈希值或前一块的哈希
    output reg [255:0] hash_out,       // 压缩后的哈希值
    output reg         hash_out_valid  // 哈希输出有效信号
);

  // =============================================
  // 内部寄存器定义
  // =============================================
  reg [ 31:0] K                                        [0:63];  // SHA-256常量

  // 32级流水线寄存器
  reg [ 31:0] a                                        [0:31];  // a工作变量流水线
  reg [ 31:0] b                                        [0:31];  // b工作变量流水线
  reg [ 31:0] c                                        [0:31];  // c工作变量流水线
  reg [ 31:0] d                                        [0:31];  // d工作变量流水线
  reg [ 31:0] e                                        [0:31];  // e工作变量流水线
  reg [ 31:0] f                                        [0:31];  // f工作变量流水线
  reg [ 31:0] g                                        [0:31];  // g工作变量流水线
  reg [ 31:0] h                                        [0:31];  // h工作变量流水线

  reg [255:0] hash_reg;  // 输入哈希值寄存器
  reg [  5:0] wt_counter;  // Wt计数器 (0-63)
  reg         zip_active;  // 压缩过程激活标志
  reg         output_stage;  // 输出阶段标志

  // =============================================
  // Σ函数定义
  // =============================================
  function [31:0] SIGMA0;
    input [31:0] x;
    SIGMA0 = {x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]};
  endfunction

  function [31:0] SIGMA1;
    input [31:0] x;
    SIGMA1 = {x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]};
  endfunction

  // =============================================
  // 选择函数和多数函数
  // =============================================
  function [31:0] Ch;
    input [31:0] x, y, z;
    Ch = (x & y) ^ (~x & z);
  endfunction

  function [31:0] Maj;
    input [31:0] x, y, z;
    Maj = (x & y) ^ (x & z) ^ (y & z);
  endfunction

  // =============================================
  // 常量初始化
  // =============================================
  initial begin
    K[0]  = 32'h428a2f98;
    K[1]  = 32'h71374491;
    K[2]  = 32'hb5c0fbcf;
    K[3]  = 32'he9b5dba5;
    K[4]  = 32'h3956c25b;
    K[5]  = 32'h59f111f1;
    K[6]  = 32'h923f82a4;
    K[7]  = 32'hab1c5ed5;
    K[8]  = 32'hd807aa98;
    K[9]  = 32'h12835b01;
    K[10] = 32'h243185be;
    K[11] = 32'h550c7dc3;
    K[12] = 32'h72be5d74;
    K[13] = 32'h80deb1fe;
    K[14] = 32'h9bdc06a7;
    K[15] = 32'hc19bf174;
    K[16] = 32'he49b69c1;
    K[17] = 32'hefbe4786;
    K[18] = 32'h0fc19dc6;
    K[19] = 32'h240ca1cc;
    K[20] = 32'h2de92c6f;
    K[21] = 32'h4a7484aa;
    K[22] = 32'h5cb0a9dc;
    K[23] = 32'h76f988da;
    K[24] = 32'h983e5152;
    K[25] = 32'ha831c66d;
    K[26] = 32'hb00327c8;
    K[27] = 32'hbf597fc7;
    K[28] = 32'hc6e00bf3;
    K[29] = 32'hd5a79147;
    K[30] = 32'h06ca6351;
    K[31] = 32'h14292967;
    K[32] = 32'h27b70a85;
    K[33] = 32'h2e1b2138;
    K[34] = 32'h4d2c6dfc;
    K[35] = 32'h53380d13;
    K[36] = 32'h650a7354;
    K[37] = 32'h766a0abb;
    K[38] = 32'h81c2c92e;
    K[39] = 32'h92722c85;
    K[40] = 32'ha2bfe8a1;
    K[41] = 32'ha81a664b;
    K[42] = 32'hc24b8b70;
    K[43] = 32'hc76c51a3;
    K[44] = 32'hd192e819;
    K[45] = 32'hd6990624;
    K[46] = 32'hf40e3585;
    K[47] = 32'h106aa070;
    K[48] = 32'h19a4c116;
    K[49] = 32'h1e376c08;
    K[50] = 32'h2748774c;
    K[51] = 32'h34b0bcb5;
    K[52] = 32'h391c0cb3;
    K[53] = 32'h4ed8aa4a;
    K[54] = 32'h5b9cca4f;
    K[55] = 32'h682e6ff3;
    K[56] = 32'h748f82ee;
    K[57] = 32'h78a5636f;
    K[58] = 32'h84c87814;
    K[59] = 32'h8cc70208;
    K[60] = 32'h90befffa;
    K[61] = 32'ha4506ceb;
    K[62] = 32'hbef9a3f7;
    K[63] = 32'hc67178f2;
  end

  // =============================================
  // 中间计算信号
  // =============================================
  reg [31:0] a0, b0, c0, d0, e0, f0, g0, h0;
  reg [31:0] T1, T2;

  // =============================================
  // 主压缩逻辑
  // =============================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位所有寄存器
      for (integer i = 0; i < 32; i++) begin
        a[i] <= 0;
        b[i] <= 0;
        c[i] <= 0;
        d[i] <= 0;
        e[i] <= 0;
        f[i] <= 0;
        g[i] <= 0;
        h[i] <= 0;
      end
      hash_reg       <= 0;
      wt_counter     <= 0;
      zip_active     <= 0;
      output_stage   <= 0;
      hash_out       <= 0;
      hash_out_valid <= 0;
    end else begin
      // 默认输出无效
      hash_out_valid <= 0;

      // ------------------------------
      // 压缩过程初始化
      // ------------------------------
      if (Wt_valid && !zip_active) begin
        // 处理第一个Wt
        a0 = hash_in[255:224];
        b0 = hash_in[223:192];
        c0 = hash_in[191:160];
        d0 = hash_in[159:128];
        e0 = hash_in[127:96];
        f0 = hash_in[95:64];
        g0 = hash_in[63:32];
        h0 = hash_in[31:0];
        T1 = h0 + SIGMA1(e0) + Ch(e0, f0, g0) + K[0] + Wt_in;
        T2 = SIGMA0(a0) + Maj(a0, b0, c0);

        a[0] <= T1 + T2;
        b[0] <= a0;
        c[0] <= b0;
        d[0] <= c0;
        e[0] <= d0 + T1;
        f[0] <= e0;
        g[0] <= f0;
        h[0] <= g0;

        // 初始化其他寄存器
        for (integer i = 1; i < 32; i++) begin
          a[i] <= 0;
          b[i] <= 0;
          c[i] <= 0;
          d[i] <= 0;
          e[i] <= 0;
          f[i] <= 0;
          g[i] <= 0;
          h[i] <= 0;
        end

        hash_reg   <= hash_in;
        zip_active <= 1;
        wt_counter <= 0;
      end

      // ------------------------------
      // 压缩处理阶段
      // ------------------------------
      if (Wt_valid && zip_active) begin
        a0 = a[0];
        b0 = b[0];
        c0 = c[0];
        d0 = d[0];
        e0 = e[0];
        f0 = f[0];
        g0 = g[0];
        h0 = h[0];

        // 更新流水线寄存器 - 右移
        for (integer i = 31; i > 0; i--) begin
          a[i] <= a[i-1];
          b[i] <= b[i-1];
          c[i] <= c[i-1];
          d[i] <= d[i-1];
          e[i] <= e[i-1];
          f[i] <= f[i-1];
          g[i] <= g[i-1];
          h[i] <= h[i-1];
        end

        // 计算新的工作变量并存入第0级
        T1 = h0 + SIGMA1(e0) + Ch(e0, f0, g0) + K[wt_counter+1] + Wt_in;
        T2 = SIGMA0(a0) + Maj(a0, b0, c0);
        a[0] <= T1 + T2;
        b[0] <= a0;
        c[0] <= b0;
        d[0] <= c0;
        e[0] <= d0 + T1;
        f[0] <= e0;
        g[0] <= f0;
        h[0] <= g0;

        // 更新计数器
        wt_counter <= wt_counter + 1;
      end

      // ------------------------------
      // 64个Wt处理完毕后，结束压缩过程
      // ------------------------------
      if (zip_active && wt_counter == 63) begin
        zip_active   <= 0;
        wt_counter   <= 0;
        output_stage <= 1;
      end

      // ------------------------------
      // 输出阶段
      // ------------------------------
      if (output_stage) begin
        // 计算最终哈希值
        hash_out <= {
          hash_reg[255:224] + a[0],
          hash_reg[223:192] + b[0],
          hash_reg[191:160] + c[0],
          hash_reg[159:128] + d[0],
          hash_reg[127:96] + e[0],
          hash_reg[95:64] + f[0],
          hash_reg[63:32] + g[0],
          hash_reg[31:0] + h[0]
        };

        hash_out_valid <= 1;
        output_stage <= 0;
      end
    end
  end

endmodule
