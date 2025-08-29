`timescale 1ns / 1ps

module tb_sha256_top ();

  reg clk;
  reg rst_n;
  reg valid_in;
  reg is_last;
  reg [511:0] block_in;

  wire pause;
  wire valid_out;
  wire [255:0] hash_out;

  sha256_top u_top (
      .clk(clk),
      .rst_n(rst_n),
      .block_in(block_in),
      .valid_in(valid_in),
      .is_last(is_last),
      .pause(pause),
      .hash_out(hash_out),
      .valid_out(valid_out)
  );

  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  initial begin
    // =============================================
    // Single Message Test————Single Block
    // =============================================
    @(negedge clk);
    rst_n = 0;
    block_in = 512'b0;
    valid_in = 1'b0;
    is_last = 1'b0;

    #10;
    rst_n = 1;

    @(negedge clk);
    block_in = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
    valid_in = 1'b1;
    is_last = 1'b1;

    @(negedge clk);
    valid_in = 1'b0;

    wait (valid_out);
    @(posedge clk);

    // =============================================
    // Continuous Messages Test————Single Block and Multiple Blocks
    // =============================================
    @(negedge clk);
    rst_n = 0;
    block_in = 512'b0;
    valid_in = 1'b0;
    is_last = 1'b0;

    #10;
    rst_n = 1;

    // First Message————Single Block
    @(negedge clk);
    block_in = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
    valid_in = 1'b1;
    is_last = 1'b1;

    // Second Message————Single Block
    @(negedge clk);
    block_in = 512'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    valid_in = 1'b1;
    is_last = 1'b1;

    // Third Message————First Block
    @(negedge clk);
    block_in = 512'h6162636462636465636465666465666765666768666768696768696a68696a6b696a6b6c6a6b6c6d6b6c6d6e6c6d6e6f6d6e6f706e6f70718000000000000000;
    valid_in = 1'b1;
    is_last = 1'b0;
    @(negedge clk);
    valid_in = 1'b0;

    // Third Message————Second Block
    wait (!pause);
    @(negedge clk);
    block_in = 512'h000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c0;
    valid_in = 1'b1;
    is_last = 1'b1;
    @(negedge clk);
    valid_in = 1'b0;

    // Fourth Message————Single Block
    wait (!pause);
    @(negedge clk);
    block_in = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
    valid_in = 1'b1;
    is_last = 1'b1;

    // Fifth Message————Single Block
    @(negedge clk);
    block_in = 512'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    valid_in = 1'b1;
    is_last = 1'b1;

    @(negedge clk);
    valid_in = 1'b0;

    #100;
    $finish;
  end

  initial begin
    $dumpfile("tb_sha256_top.vcd");
    $dumpvars(0, tb_sha256_top.u_top);
  end

endmodule
