`timescale 1ns / 1ns
`ifndef TESTFILE
`define TESTFILE "../testfiles/queue_tf.hex"
`endif

module queue_tb();

  localparam period    = 4;
  localparam max_test  = 20;
  localparam data_size = 4;
  localparam test_size = 5+data_size*2;

  reg clk_r;

  // module connections
  // input data
  reg                  rst_t; 
  reg                  wr_req_t;
  reg                  r_req_t;
  reg  [data_size-1:0] data_i_t;
  // output data
  wire                 full_t;
  wire                 empty_t;
  wire [data_size-1:0] data_o_t;
  // output expected
  reg                  full_exp;
  reg                  empty_exp;
  reg  [data_size-1:0] data_o_exp;

  queue #(
    .DATA_SIZE (4),
    .PTR_SIZE  (2)
  ) test_queue (
    .clk    (clk_r    ),
    .a_rst  (rst_t    ),
    .wr_req (wr_req_t ),
    .r_req  (r_req_t  ),
    .data_i (data_i_t ),
    .data_o (data_o_t ),
    .full   (full_t   ),
    .empty  (empty_t  )
  );
  
  // clk generate
  initial
    begin
      clk_r = 1'b0;
      forever
        #(period/2) clk_r = ~clk_r;
    end

  // data load, indexes init
  integer test_idx;
  integer errors_num;
  reg [test_size-1:0] test_data [max_test-1:0];
  initial
    begin
      test_idx = 0;
      errors_num = 0;
      $readmemh(`TESTFILE, test_data);
      rst_t = 1'b1;
    end

  always @(posedge clk_r)
    {rst_t, wr_req_t, r_req_t, full_exp, empty_exp, data_i_t, data_o_exp} = test_data[test_idx];

  always @(posedge clk_r)
    begin
     #(period/4);
      if (full_exp !== full_t || empty_exp !== empty_t || data_o_exp !== data_o_t)
        begin
          $display("Error in %d test:\n", test_idx);
          $display("Output  : full = %b, empty = %b, data_o = %b\n", full_t, empty_t, data_o_t);
          $display("Expected: full = %b, empty = %b, data_o = %b\n" , full_exp, empty_exp, data_o_exp);
          errors_num = errors_num + 1;
        end
      test_idx = test_idx + 1;
      if (test_idx == max_test || test_data[test_idx] === {test_size{1'bx}})
        begin
          $display("Finish: %d tests, %d errors\n", test_idx, errors_num);
          $finish;
        end
    end
endmodule