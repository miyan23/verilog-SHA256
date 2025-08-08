/*
 * 模块名称：expand
 *
 * 功能描述：
 *   本模块用于对输入的512位消息块进行SHA-256算法所需的消息扩展。
 *   采用16级流水线结构，每周期输出一个扩展后的消息字Wt。
 *   支持连续块处理，使用FIFO缓存机制处理任意数量的连续输入块。
 *
 * 扩展规则：
 *   1. 前16个字直接取自输入消息块
 *   2. 后48个字通过扩展算法生成：W[t] = σ1(W[t-2]) + W[t-7] + σ0(W[t-15]) + W[t-16]
 */

module sha256_expand (
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
  reg [31:0] W                                           [0:63];  // 消息调度数组
  reg [31:0] pipeline_reg                                [0:15];  // 16级流水线寄存器
  reg [ 6:0] expand_counter;  // 扩展计数器 (0-63)
  reg        expand_active;  // 扩展过程激活标志

  // FIFO缓存定义
  parameter FIFO_DEPTH = 16;  // FIFO深度，可根据需要调整
  reg     [511:0] fifo                                [0:FIFO_DEPTH-1];  // FIFO存储
  reg     [  4:0] fifo_wr_ptr;  // FIFO写指针
  reg     [  4:0] fifo_rd_ptr;  // FIFO读指针
  reg     [  4:0] fifo_count;  // FIFO中有效块数

  // for循环变量
  integer         i;

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
      for (i = 0; i < 64; i = i + 1) begin
        W[i] <= 0;
      end
      for (i = 0; i < 16; i = i + 1) begin
        pipeline_reg[i] <= 0;
      end
      expand_counter <= 0;
      expand_active  <= 0;
      Wt_out         <= 0;
      Wt_valid       <= 0;

      // 复位FIFO
      for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
        fifo[i] <= 0;
      end
      fifo_wr_ptr <= 0;
      fifo_rd_ptr <= 0;
      fifo_count  <= 0;

    end else begin
      // 默认输出无效
      Wt_valid <= 0;

      // ------------------------------
      // 输入块处理（FIFO写入）
      // ------------------------------
      if (block_valid && fifo_count < FIFO_DEPTH) begin
        fifo[fifo_wr_ptr] <= block_in;
        fifo_count <= fifo_count + 5'd1;

        // 写指针绕回处理
        fifo_wr_ptr <= (fifo_wr_ptr == FIFO_DEPTH - 1) ? 5'd0 : fifo_wr_ptr + 5'd1;
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
          pipeline_reg[0]  <= pipeline_reg[1];
          pipeline_reg[1]  <= pipeline_reg[2];
          pipeline_reg[2]  <= pipeline_reg[3];
          pipeline_reg[3]  <= pipeline_reg[4];
          pipeline_reg[4]  <= pipeline_reg[5];
          pipeline_reg[5]  <= pipeline_reg[6];
          pipeline_reg[6]  <= pipeline_reg[7];
          pipeline_reg[7]  <= pipeline_reg[8];
          pipeline_reg[8]  <= pipeline_reg[9];
          pipeline_reg[9]  <= pipeline_reg[10];
          pipeline_reg[10] <= pipeline_reg[11];
          pipeline_reg[11] <= pipeline_reg[12];
          pipeline_reg[12] <= pipeline_reg[13];
          pipeline_reg[13] <= pipeline_reg[14];
          pipeline_reg[14] <= pipeline_reg[15];

          if (expand_counter < 80) begin
            // 延迟16周期
            pipeline_reg[15] <= W[expand_counter-16];

          end else begin
            // 超出范围时清零
            pipeline_reg[15] <= 0;
          end

          // 输出当前Wt
          if (expand_counter >= 32) begin
            Wt_out   <= pipeline_reg[0];
            Wt_valid <= 1;
          end

          expand_counter <= expand_counter + 7'd1;

        end else begin
          // 当前块扩展完成
          expand_active <= 0;
          Wt_valid      <= 0;

          // 检查FIFO中是否有待处理块
          if (fifo_count > 0) begin
            // 从FIFO读取下一个块
            case (fifo_rd_ptr)
              default: begin
                W[0]  <= fifo[fifo_rd_ptr][511:480];
                W[1]  <= fifo[fifo_rd_ptr][479:448];
                W[2]  <= fifo[fifo_rd_ptr][447:416];
                W[3]  <= fifo[fifo_rd_ptr][415:384];
                W[4]  <= fifo[fifo_rd_ptr][383:352];
                W[5]  <= fifo[fifo_rd_ptr][351:320];
                W[6]  <= fifo[fifo_rd_ptr][319:288];
                W[7]  <= fifo[fifo_rd_ptr][287:256];
                W[8]  <= fifo[fifo_rd_ptr][255:224];
                W[9]  <= fifo[fifo_rd_ptr][223:192];
                W[10] <= fifo[fifo_rd_ptr][191:160];
                W[11] <= fifo[fifo_rd_ptr][159:128];
                W[12] <= fifo[fifo_rd_ptr][127:96];
                W[13] <= fifo[fifo_rd_ptr][95:64];
                W[14] <= fifo[fifo_rd_ptr][63:32];
                W[15] <= fifo[fifo_rd_ptr][31:0];
              end
            endcase
            expand_counter <= 16;
            expand_active <= 1;

            // 读指针绕回处理
            fifo_rd_ptr <= (fifo_rd_ptr == FIFO_DEPTH - 1) ? 5'd0 : fifo_rd_ptr + 5'd1;
            fifo_count <= fifo_count - 5'd1;
          end
        end

      end else if (fifo_count > 0) begin
        // 当前无处理块且FIFO不为空，开始处理下一个块
        case (fifo_rd_ptr)
          default: begin
            W[0]  <= fifo[fifo_rd_ptr][511:480];
            W[1]  <= fifo[fifo_rd_ptr][479:448];
            W[2]  <= fifo[fifo_rd_ptr][447:416];
            W[3]  <= fifo[fifo_rd_ptr][415:384];
            W[4]  <= fifo[fifo_rd_ptr][383:352];
            W[5]  <= fifo[fifo_rd_ptr][351:320];
            W[6]  <= fifo[fifo_rd_ptr][319:288];
            W[7]  <= fifo[fifo_rd_ptr][287:256];
            W[8]  <= fifo[fifo_rd_ptr][255:224];
            W[9]  <= fifo[fifo_rd_ptr][223:192];
            W[10] <= fifo[fifo_rd_ptr][191:160];
            W[11] <= fifo[fifo_rd_ptr][159:128];
            W[12] <= fifo[fifo_rd_ptr][127:96];
            W[13] <= fifo[fifo_rd_ptr][95:64];
            W[14] <= fifo[fifo_rd_ptr][63:32];
            W[15] <= fifo[fifo_rd_ptr][31:0];
          end
        endcase
        expand_counter <= 16;
        expand_active <= 1;

        // 读指针绕回处理
        fifo_rd_ptr <= (fifo_rd_ptr == FIFO_DEPTH - 1) ? 5'd0 : fifo_rd_ptr + 5'd1;
        fifo_count <= fifo_count - 5'd1;
      end
    end
  end

endmodule
