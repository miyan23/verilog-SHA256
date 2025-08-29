/*
 * 模块名称：sha256_calculate_h
 *
 * 功能描述：
 *   本模块实现SHA-256算法中单轮哈希值的计算，包括T1、T2的生成和中间哈希值的更新。
 *
 * 主要特点：
 *   1. 组合逻辑实现，无时钟延迟
 *   2. 支持SIGMA0、SIGMA1、Ch、Maj等SHA-256核心函数
 *   3. 使用两次反转的方法避免new_x信号被综合优化
 *
 * 接口说明：
 *   输入：
 *     - hash_middle_in：当前轮次的中间哈希值（256位）
 *     - k_t           ：当前轮次的常量K（32位）
 *     - w_t           ：当前轮次的消息字W（32位）
 *   输出：
 *     - hash_middle_out：下一轮次的中间哈希值（256位）
 */

module sha256_calculate_h (
    input wire [255:0] hash_middle_in,
    input wire [ 31:0] k_t,
    input wire [ 31:0] w_t,

    output wire [255:0] hash_middle_out
);

  wire [31:0] a, b, c, d, e, f, g, h;
  wire [31:0] new_a, new_b, new_c, new_d, new_e, new_f, new_g, new_h;
  wire [31:0] T1, T2;

  assign a = hash_middle_in[255:224];
  assign b = hash_middle_in[223:192];
  assign c = hash_middle_in[191:160];
  assign d = hash_middle_in[159:128];
  assign e = hash_middle_in[127:96];
  assign f = hash_middle_in[95:64];
  assign g = hash_middle_in[63:32];
  assign h = hash_middle_in[31:0];

  assign T1 = h + SIGMA1(e) + Ch(e, f, g) + k_t + w_t;
  assign T2 = SIGMA0(a) + Maj(a, b, c);

  assign new_a = T1 + T2;
  assign new_b = ~(~a);
  assign new_c = ~(~b);
  assign new_d = ~(~c);
  assign new_e = d + T1;
  assign new_f = ~(~e);
  assign new_g = ~(~f);
  assign new_h = ~(~g);

  assign hash_middle_out = {new_a, new_b, new_c, new_d, new_e, new_f, new_g, new_h};

  function [31:0] SIGMA0;
    input [31:0] x;

    begin
      SIGMA0 = {x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]};
    end
  endfunction

  function [31:0] SIGMA1;
    input [31:0] x;

    begin
      SIGMA1 = {x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]};
    end
  endfunction

  function [31:0] Ch;
    input [31:0] x, y, z;

    begin
      Ch = (x & y) ^ (~x & z);
    end
  endfunction

  function [31:0] Maj;
    input [31:0] x, y, z;

    begin
      Maj = (x & y) ^ (x & z) ^ (y & z);
    end
  endfunction

endmodule
