`timescale 1ns / 1ns

module fabric_tb();
  
  localparam period   = 2;
  localparam max_test = 300;

  integer test_idx;

  reg clk_r;
  reg rst_r;

  // connect ip to itself
  wire [5:0] data_0_o, data_1_o;
  wire out_w_0, out_w_1, in_r_0, in_r_1;

  fabric #(
    .DATA_SIZE(4),
    .ADDR_SIZE(1),
    .ADDR(0),
    .NODES_NUM(2),
    .PACKS_TO_GEN(10),
    .MAX_PACK_LEN(10),
    .DEBUG(1)
  ) IP0 (
    .clk      (clk_r),
    .a_rst    (rst_r),
    .data_i   (data_1_o),
    .data_o   (data_0_o), 
    .out_w    (out_w_0),
    .in_r     (in_r_0),
    .out_r    (in_r_1),
    .in_w     (out_w_1)
  );

  fabric #(
    .DATA_SIZE(4),
    .ADDR_SIZE(1),
    .ADDR(1),
    .NODES_NUM(2),
    .PACKS_TO_GEN(10),
    .MAX_PACK_LEN(10),
    .DEBUG(1)
  ) IP1 (
    .clk      (clk_r),
    .a_rst    (rst_r),
    .data_i   (data_0_o),
    .data_o   (data_1_o),
    .out_w    (out_w_1),
    .in_r     (in_r_1),
    .out_r    (in_r_0),
    .in_w     (out_w_0)
  );

  initial
    begin
      clk_r = 1'b0;
      forever
        #(period/2) clk_r = ~clk_r;
    end

  initial
    begin
      test_idx = 0;
      rst_r = 1'b1;
      #(2) rst_r = 1'b0;
    end
  
  always @(posedge clk_r)
    begin
      // if (test_idx == 10)
        // $stop;  
      if (test_idx == max_test)
        begin
          $display("Test has been finished");
          $finish;
        end
      test_idx = test_idx + 1;
    end
  
endmodule
