/*
 * 模块名称：padding
 *
 * 功能描述：
 *   本模块用于对输入的消息进行SHA-256算法所需的填充处理，将任意长度的消息填充为512位的整数倍。
 *   填充规则遵循SHA-256标准：
 *     1. 在消息末尾添加一个"1"位（即字节0x80）
 *     2. 填充"0"位直到消息长度满足 (长度 % 512) = 448
 *     3. 最后64位填充原始消息的位长度（大端序）
 *
 * 输入输出：
 *   - 输入：8位消息字节(data_in)及其有效信号(data_in_valid)，结束标志(data_last)
 *   - 输出：填充后的512位数据块(data_out)及其有效信号(data_out_valid)，模块就绪信号(data_ready)
 */

module sha256_padding (
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
  localparam OUTPUT_FULL_1 = 4'b0010;  //块满（大于等56字节小于64字节-输入结束）
  localparam OUTPUT_FULL_2 = 4'b0011;  //块满（等于64字节-输入结束）
  localparam OUTPUT_FULL_3 = 4'b0100;  //块满（等于64字节）
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
    end else begin
      // 默认输出无效
      data_out_valid <= 0;

      case (state)
        IDLE: begin
          if (data_in_valid) begin
            // 处理单字节消息
            if (data_last) begin
              data_length <= 64'd8;
              temp_block[511:504] <= data_in;
              byte_count <= 1;
              state <= PAD_1;
              data_ready <= 0;
            end else begin
              // 正常接收数据
              state               <= RECEIVE;
              data_length         <= 64'd8;
              temp_block[511:504] <= data_in;
              byte_count          <= 1;
            end
          end else if (data_last) begin
            // 处理空消息情况（只有data_last信号）
            state <= PAD_1;
            data_ready <= 0;
          end
        end

        RECEIVE: begin
          if (data_in_valid) begin
            data_length <= data_length + 64'd8;
            case (byte_count)
              1:  temp_block[503:496] <= data_in;
              2:  temp_block[495:488] <= data_in;
              3:  temp_block[487:480] <= data_in;
              4:  temp_block[479:472] <= data_in;
              5:  temp_block[471:464] <= data_in;
              6:  temp_block[463:456] <= data_in;
              7:  temp_block[455:448] <= data_in;
              8:  temp_block[447:440] <= data_in;
              9:  temp_block[439:432] <= data_in;
              10: temp_block[431:424] <= data_in;
              11: temp_block[423:416] <= data_in;
              12: temp_block[415:408] <= data_in;
              13: temp_block[407:400] <= data_in;
              14: temp_block[399:392] <= data_in;
              15: temp_block[391:384] <= data_in;
              16: temp_block[383:376] <= data_in;
              17: temp_block[375:368] <= data_in;
              18: temp_block[367:360] <= data_in;
              19: temp_block[359:352] <= data_in;
              20: temp_block[351:344] <= data_in;
              21: temp_block[343:336] <= data_in;
              22: temp_block[335:328] <= data_in;
              23: temp_block[327:320] <= data_in;
              24: temp_block[319:312] <= data_in;
              25: temp_block[311:304] <= data_in;
              26: temp_block[303:296] <= data_in;
              27: temp_block[295:288] <= data_in;
              28: temp_block[287:280] <= data_in;
              29: temp_block[279:272] <= data_in;
              30: temp_block[271:264] <= data_in;
              31: temp_block[263:256] <= data_in;
              32: temp_block[255:248] <= data_in;
              33: temp_block[247:240] <= data_in;
              34: temp_block[239:232] <= data_in;
              35: temp_block[231:224] <= data_in;
              36: temp_block[223:216] <= data_in;
              37: temp_block[215:208] <= data_in;
              38: temp_block[207:200] <= data_in;
              39: temp_block[199:192] <= data_in;
              40: temp_block[191:184] <= data_in;
              41: temp_block[183:176] <= data_in;
              42: temp_block[175:168] <= data_in;
              43: temp_block[167:160] <= data_in;
              44: temp_block[159:152] <= data_in;
              45: temp_block[151:144] <= data_in;
              46: temp_block[143:136] <= data_in;
              47: temp_block[135:128] <= data_in;
              48: temp_block[127:120] <= data_in;
              49: temp_block[119:112] <= data_in;
              50: temp_block[111:104] <= data_in;
              51: temp_block[103:96] <= data_in;
              52: temp_block[95:88] <= data_in;
              53: temp_block[87:80] <= data_in;
              54: temp_block[79:72] <= data_in;
              55: temp_block[71:64] <= data_in;
              56: temp_block[63:56] <= data_in;
              57: temp_block[55:48] <= data_in;
              58: temp_block[47:40] <= data_in;
              59: temp_block[39:32] <= data_in;
              60: temp_block[31:24] <= data_in;
              61: temp_block[23:16] <= data_in;
              62: temp_block[15:8] <= data_in;
              63: temp_block[7:0] <= data_in;
            endcase
            byte_count <= byte_count + 6'd1;

            if (data_last) begin
              if (byte_count < 55) begin
                state <= PAD_1;

              end else if (byte_count >= 55 && byte_count < 63) begin
                case (byte_count)
                  55: temp_block[63:56] <= 8'h80;
                  56: temp_block[55:48] <= 8'h80;
                  57: temp_block[47:40] <= 8'h80;
                  58: temp_block[39:32] <= 8'h80;
                  59: temp_block[31:24] <= 8'h80;
                  60: temp_block[23:16] <= 8'h80;
                  61: temp_block[15:8] <= 8'h80;
                  62: temp_block[7:0] <= 8'h80;
                endcase
                state <= OUTPUT_FULL_1;

              end else if (byte_count == 63) begin
                state <= OUTPUT_FULL_2;
              end

              data_ready <= 0;
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
          byte_count     <= 0;

          state          <= PAD_0;
        end

        OUTPUT_FULL_2: begin
          data_out       <= temp_block;
          data_out_valid <= 1;

          temp_block     <= 0;
          byte_count     <= 0;

          state          <= PAD_1;
        end

        OUTPUT_FULL_3: begin
          data_out <= temp_block;
          data_out_valid <= 1;

          data_length <= data_length + 64'd8;
          temp_block[511:504] <= data_in;
          byte_count <= 1;

          state <= RECEIVE;
        end

        PAD_1: begin
          // 添加填充位"1" (0x80)
          case (byte_count)
            0:  temp_block[511:504] = 8'h80;
            1:  temp_block[503:496] = 8'h80;
            2:  temp_block[495:488] = 8'h80;
            3:  temp_block[487:480] = 8'h80;
            4:  temp_block[479:472] = 8'h80;
            5:  temp_block[471:464] = 8'h80;
            6:  temp_block[463:456] = 8'h80;
            7:  temp_block[455:448] = 8'h80;
            8:  temp_block[447:440] = 8'h80;
            9:  temp_block[439:432] = 8'h80;
            10: temp_block[431:424] = 8'h80;
            11: temp_block[423:416] = 8'h80;
            12: temp_block[415:408] = 8'h80;
            13: temp_block[407:400] = 8'h80;
            14: temp_block[399:392] = 8'h80;
            15: temp_block[391:384] = 8'h80;
            16: temp_block[383:376] = 8'h80;
            17: temp_block[375:368] = 8'h80;
            18: temp_block[367:360] = 8'h80;
            19: temp_block[359:352] = 8'h80;
            20: temp_block[351:344] = 8'h80;
            21: temp_block[343:336] = 8'h80;
            22: temp_block[335:328] = 8'h80;
            23: temp_block[327:320] = 8'h80;
            24: temp_block[319:312] = 8'h80;
            25: temp_block[311:304] = 8'h80;
            26: temp_block[303:296] = 8'h80;
            27: temp_block[295:288] = 8'h80;
            28: temp_block[287:280] = 8'h80;
            29: temp_block[279:272] = 8'h80;
            30: temp_block[271:264] = 8'h80;
            31: temp_block[263:256] = 8'h80;
            32: temp_block[255:248] = 8'h80;
            33: temp_block[247:240] = 8'h80;
            34: temp_block[239:232] = 8'h80;
            35: temp_block[231:224] = 8'h80;
            36: temp_block[223:216] = 8'h80;
            37: temp_block[215:208] = 8'h80;
            38: temp_block[207:200] = 8'h80;
            39: temp_block[199:192] = 8'h80;
            40: temp_block[191:184] = 8'h80;
            41: temp_block[183:176] = 8'h80;
            42: temp_block[175:168] = 8'h80;
            43: temp_block[167:160] = 8'h80;
            44: temp_block[159:152] = 8'h80;
            45: temp_block[151:144] = 8'h80;
            46: temp_block[143:136] = 8'h80;
            47: temp_block[135:128] = 8'h80;
            48: temp_block[127:120] = 8'h80;
            49: temp_block[119:112] = 8'h80;
            50: temp_block[111:104] = 8'h80;
            51: temp_block[103:96] = 8'h80;
            52: temp_block[95:88] = 8'h80;
            53: temp_block[87:80] = 8'h80;
            54: temp_block[79:72] = 8'h80;
            55: temp_block[71:64] = 8'h80;
            56: temp_block[63:56] = 8'h80;
            57: temp_block[55:48] = 8'h80;
            58: temp_block[47:40] = 8'h80;
            59: temp_block[39:32] = 8'h80;
            60: temp_block[31:24] = 8'h80;
            61: temp_block[23:16] = 8'h80;
            62: temp_block[15:8] = 8'h80;
            63: temp_block[7:0] = 8'h80;
          endcase
          byte_count <= byte_count + 6'd1;
          state    <= PAD_0;
        end

        PAD_0: begin
          if (byte_count < 56) begin
            case (byte_count)
              0:  temp_block[511:504] = 8'h00;
              1:  temp_block[503:496] = 8'h00;
              2:  temp_block[495:488] = 8'h00;
              3:  temp_block[487:480] = 8'h00;
              4:  temp_block[479:472] = 8'h00;
              5:  temp_block[471:464] = 8'h00;
              6:  temp_block[463:456] = 8'h00;
              7:  temp_block[455:448] = 8'h00;
              8:  temp_block[447:440] = 8'h00;
              9:  temp_block[439:432] = 8'h00;
              10: temp_block[431:424] = 8'h00;
              11: temp_block[423:416] = 8'h00;
              12: temp_block[415:408] = 8'h00;
              13: temp_block[407:400] = 8'h00;
              14: temp_block[399:392] = 8'h00;
              15: temp_block[391:384] = 8'h00;
              16: temp_block[383:376] = 8'h00;
              17: temp_block[375:368] = 8'h00;
              18: temp_block[367:360] = 8'h00;
              19: temp_block[359:352] = 8'h00;
              20: temp_block[351:344] = 8'h00;
              21: temp_block[343:336] = 8'h00;
              22: temp_block[335:328] = 8'h00;
              23: temp_block[327:320] = 8'h00;
              24: temp_block[319:312] = 8'h00;
              25: temp_block[311:304] = 8'h00;
              26: temp_block[303:296] = 8'h00;
              27: temp_block[295:288] = 8'h00;
              28: temp_block[287:280] = 8'h00;
              29: temp_block[279:272] = 8'h00;
              30: temp_block[271:264] = 8'h00;
              31: temp_block[263:256] = 8'h00;
              32: temp_block[255:248] = 8'h00;
              33: temp_block[247:240] = 8'h00;
              34: temp_block[239:232] = 8'h00;
              35: temp_block[231:224] = 8'h00;
              36: temp_block[223:216] = 8'h00;
              37: temp_block[215:208] = 8'h00;
              38: temp_block[207:200] = 8'h00;
              39: temp_block[199:192] = 8'h00;
              40: temp_block[191:184] = 8'h00;
              41: temp_block[183:176] = 8'h00;
              42: temp_block[175:168] = 8'h00;
              43: temp_block[167:160] = 8'h00;
              44: temp_block[159:152] = 8'h00;
              45: temp_block[151:144] = 8'h00;
              46: temp_block[143:136] = 8'h00;
              47: temp_block[135:128] = 8'h00;
              48: temp_block[127:120] = 8'h00;
              49: temp_block[119:112] = 8'h00;
              50: temp_block[111:104] = 8'h00;
              51: temp_block[103:96] = 8'h00;
              52: temp_block[95:88] = 8'h00;
              53: temp_block[87:80] = 8'h00;
              54: temp_block[79:72] = 8'h00;
              55: temp_block[71:64] = 8'h00;
            endcase
            byte_count <= byte_count + 6'd1;
          end else begin
            state <= PAD_LEN;
          end
        end

        PAD_LEN: begin
          // 添加消息长度
          temp_block[63:0] <= data_length;
          state <= OUTPUT_LAST;
        end

        OUTPUT_LAST: begin
          // 输出最后一个填充块
          data_out       <= temp_block;
          data_out_valid <= 1;

          // 重置状态
          temp_block     <= 0;
          byte_count     <= 0;
          data_length    <= 0;
          state          <= IDLE;
          data_ready     <= 1;
        end

        default: begin
          state <= IDLE;
          data_ready <= 1;
        end
      endcase
    end
  end

endmodule
