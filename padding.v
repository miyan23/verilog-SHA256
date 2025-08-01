module padding (
    input              clk,
    input              rst_n,
    input      [  7:0] data_in,         // 输入消息字节
    input              data_in_valid,   // 输入消息有效信号
    input              data_last,       // 输入消息最后一个字节标志
    output reg [511:0] data_out,        // 输出填充后的512位数据块
    output reg         data_out_valid,  // 输出数据块有效信号
    output reg         data_ready       // 模块就绪信号（可接收新输入）
);

  // =============================================
  // 状态定义
  // =============================================
  localparam IDLE = 4'b0000;  // 等待输入
  localparam RECEIVE = 4'b0001;  // 接收输入
  localparam OUTPUT_FULL_1 = 4'b0010;
  localparam OUTPUT_FULL_2 = 4'b0011;
  localparam OUTPUT_FULL_3 = 4'b0100;
  localparam PAD_1 = 4'b0101;  // 补1
  localparam PAD_0 = 4'b0110;  // 补0
  localparam PAD_LEN = 4'b0111;  // 补长度
  localparam OUTPUT_LAST = 4'b1000;  // 输出最后一个块

  // =============================================
  // 内部寄存器
  // =============================================
  reg [  3:0] state;
  reg [ 63:0] data_length;  // 原始消息长度（位）
  reg [  5:0] byte_count;  // 当前块内字节计数（0-63）
  reg [511:0] temp_block;  // 临时存储块数据
  reg [  5:0] fill_pos;  // 填充位置指针

  // =============================================
  // 主状态机逻辑
  // =============================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位所有寄存器
      state          <= IDLE;
      data_length    <= 0;
      byte_count     <= 0;
      temp_block     <= 0;
      data_out       <= 0;
      data_out_valid <= 0;
      data_ready     <= 1;  // 复位时默认可接收数据
      fill_pos       <= 0;
    end else begin
      // 默认输出无效
      data_out_valid <= 0;

      case (state)
        IDLE: begin
          // 模块就绪，等待有效输入
          data_ready <= 1;
          if (data_in_valid) begin
            // 处理单字节消息
            if (data_last) begin
              data_length <= 64'd8;
              temp_block[511-:8] <= data_in;
              byte_count <= 1;
              state <= PAD_1;
              fill_pos <= 1;
              data_ready <= 0;
            end else begin
              // 正常接收数据
              state                           <= RECEIVE;
              data_length                     <= 64'd8;
              temp_block[511-8*byte_count-:8] <= data_in;
              byte_count                      <= byte_count + 1;
              data_ready                      <= (byte_count < 63);
            end
          end else if (data_last) begin
            // 处理空消息情况（只有data_last信号）
            state <= PAD_1;
            fill_pos <= 0;
            data_ready <= 0; 
          end
        end

        RECEIVE: begin
          if (data_in_valid) begin
            data_length <= data_length + 64'd8;
            temp_block[511-8*byte_count-:8] <= data_in;
            byte_count <= byte_count + 1;
            data_ready <= (byte_count < 63);

            if (data_last) begin
              if (byte_count < 55) begin
                fill_pos <= byte_count + 1;
                data_ready <= 0;
                state <= PAD_1;
              end else if (byte_count >= 55 && byte_count < 63) begin
                temp_block[511-8*(byte_count+1)-:8] <= 8'h80;
                state <= OUTPUT_FULL_1;
              end else if (byte_count == 63) begin
                state <= OUTPUT_FULL_2;
              end
            end

            if (byte_count == 63) begin
              state <= OUTPUT_FULL_3;
            end
          end
        end

        OUTPUT_FULL_1: begin
          data_out       <= temp_block;
          data_out_valid <= 1;

          temp_block     <= 0;
          fill_pos       <= 0;
          byte_count     <= 0;
          data_ready     <= 0;

          state          <= PAD_0;
        end

        OUTPUT_FULL_2: begin
          data_out       <= temp_block;
          data_out_valid <= 1;

          temp_block     <= 0;
          fill_pos       <= 0;
          byte_count     <= 0;
          data_ready     <= 0;

          state          <= PAD_1;
        end

        OUTPUT_FULL_3: begin
          data_out <= temp_block;
          data_out_valid <= 1;

          data_length <= data_length + 64'd8;
          temp_block[511-:8] <= data_in;
          byte_count <= 1;
          data_ready <= 1;
          state <= RECEIVE;
        end

        PAD_1: begin
          // 添加填充位"1" (0x80)
          temp_block[511-8*fill_pos-:8] <= 8'h80;
          fill_pos <= fill_pos + 1;
          state    <= PAD_0;
          data_ready <= 0;
        end

        PAD_0: begin
          if (fill_pos < 56) begin
            temp_block[511-8*fill_pos-:8] <= 8'h00;
            fill_pos <= fill_pos + 1;
            data_ready <= 0;
          end else begin
            state <= PAD_LEN;
            data_ready <= 0;
          end
        end

        PAD_LEN: begin
          // 添加消息长度
          temp_block[63:0] <= data_length;
          state <= OUTPUT_LAST;
          data_ready <= 0;
        end

        OUTPUT_LAST: begin
          // 输出最后一个填充块
          data_out       <= temp_block;
          data_out_valid <= 1;

          // 重置状态
          temp_block     <= 0;
          byte_count     <= 0;
          fill_pos       <= 0;
          data_length    <= 0;
          state          <= IDLE;
          data_ready     <= 1;  // 返回就绪状态
        end

        default: begin
          state <= IDLE;
          data_ready <= 1;
        end
      endcase
    end
  end

endmodule
