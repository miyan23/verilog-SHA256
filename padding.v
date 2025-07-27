/*
 * 模块名称：padding
 *
 * 功能描述：
 *   本模块用于对输入的任意长度消息进行SHA-256算法所需的预处理（填充）。
 *   输入为按字节输入的消息及其有效信号，输出为填充后的512位数据块及块有效信号。
 *
 * 填充规则：
 *   1. 在消息末尾附加一个"1"比特（即10000000）。
 *   2. 补"0"直到消息长度满足 ≡ 448 mod 512（即剩余64位）。
 *   3. 最后补充64位，表示原始消息的位长度（采用大端序）。
 */

module padding (
    input              clk,
    input              rst_n,
    input      [  7:0] data_in,         // 输入消息字节
    input              data_in_valid,   // 输入消息有效信号
    input              data_last,       // 输入消息最后一个字节标志
    output reg [511:0] data_out,        // 输出填充后的512位数据块
    output reg         data_out_valid,  // 输出数据块有效信号
    output reg         ready            // 模块就绪信号（可接收新输入）
);

  // =============================================
  // 状态定义
  // =============================================
  localparam IDLE = 3'b000;  // 等待输入
  localparam RECEIVE = 3'b001;  // 接收输入
  localparam PAD_1 = 3'b010;  // 补1
  localparam PAD_0 = 3'b011;  // 补0
  localparam PAD_LEN = 3'b100;  // 补长度
  localparam OUTPUT = 3'b101;  // 输出数据块
  localparam SECOND_BLOCK = 3'b110;  // 处理第二个数据块

  // =============================================
  // 内部寄存器
  // =============================================
  reg [  2:0] state;
  reg [ 63:0] msg_length;  // 原始消息长度（位）
  reg [  5:0] byte_count;  // 当前块内字节计数（0-63）
  reg [511:0] temp_block;  // 临时存储块数据
  reg [  5:0] fill_pos;  // 填充位置指针
  reg         needs_second_block;  // 需要第二个块标志

  // =============================================
  // 主状态机逻辑
  // =============================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位所有寄存器
      state              <= IDLE;
      msg_length         <= 0;
      byte_count         <= 0;
      temp_block         <= 0;
      data_out           <= 0;
      data_out_valid     <= 0;
      ready              <= 0;
      fill_pos           <= 0;
      needs_second_block <= 0;
    end else begin
      // 输出状态默认无效
      data_out_valid <= 0;

      case (state)
        IDLE: begin
          // 模块就绪，等待有效输入
          ready <= 1;

          if (data_in_valid) begin
            // 单字节消息特殊处理
            if (data_last) begin
              state <= PAD_1;
              ready <= 0;
              fill_pos <= 1;
              msg_length <= 64'd8;
              temp_block[511:504] <= data_in;
            end else begin
              // 正常消息接收
              state <= RECEIVE;
              msg_length <= msg_length + 64'd8;
              temp_block[511-8*byte_count-:8] <= data_in;
              byte_count <= byte_count + 1;
              ready <= (byte_count < 63);
            end
          end else if (data_last) begin
            // 空消息处理
            state <= PAD_1;
            ready <= 0;
            fill_pos <= 0;
            msg_length <= 0;
          end
        end

        // 接收消息状态
        RECEIVE: begin
          if (data_in_valid) begin
            msg_length <= msg_length + 64'd8;
            temp_block[511-8*byte_count-:8] <= data_in;
            byte_count <= byte_count + 1;
            ready <= (byte_count < 63);

            if (byte_count == 63 || data_last) begin
              state <= PAD_1;
              ready <= 0;

              // 计算填充起始位置（考虑块边界）
              fill_pos <= (byte_count == 63) ? 0 : (byte_count + 1);
              // 检查是否需要第二个块放长度
              needs_second_block <= (byte_count >= 55);
            end
          end
        end

        // 添加填充位"1" (0x80)
        PAD_1: begin
          if (fill_pos < 64) begin
            temp_block[511-8*fill_pos-:8] <= 8'h80;
          end

          fill_pos <= fill_pos + 1;
          state <= PAD_0;
        end

        // 处理填充0的状态
        PAD_0: begin
          if (needs_second_block) begin
            // 输出第一个块
            data_out <= temp_block;
            data_out_valid <= 1;

            // 准备第二个块
            temp_block <= 0;
            fill_pos <= 0;
            state <= SECOND_BLOCK;
          end else begin
            // 单块处理
            if (fill_pos < 56) begin
              temp_block[511-8*fill_pos-:8] <= 8'h00;
              fill_pos <= fill_pos + 1;
            end else begin
              state <= PAD_LEN;
            end
          end
        end

        // 处理第二个数据块
        SECOND_BLOCK: begin
          temp_block[511:64] <= 0;
          temp_block[63:0] <= msg_length;

          state <= OUTPUT;
        end

        // 填充消息长度
        PAD_LEN: begin
          temp_block[63:0] <= msg_length;
          state <= OUTPUT;
        end

        // 输出填充完整的数据块，并重置状态
        OUTPUT: begin
          data_out <= temp_block;
          data_out_valid <= 1;

          temp_block <= 0;
          byte_count <= 0;
          fill_pos <= 0;
          state <= IDLE;
        end

        // 未知状态处理
        default: state <= IDLE;
      endcase
    end
  end

endmodule
