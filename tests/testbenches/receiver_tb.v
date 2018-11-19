`timescale 1ns / 1ns
`ifndef TESTFILE
`define TESTFILE "../testfiles/receiver_tf.bin"
`endif

module receiver_tb();

  localparam period    = 4;
  localparam max_test  = 50;
  localparam data_size = 4;
  localparam addr_size = 1;
  localparam ports_num = 4;
  localparam test_size = 3 + 2*(ports_num + 1) + (data_size+addr_size+1)*(ports_num + 1) + (data_size+addr_size+1);

  reg clk_r;

  // module connections
  // input data
  reg                                              rst_t; 
  reg                                              is_full_t;
  reg                                [ports_num:0] in_r_t;
  reg  [(data_size+addr_size+1)*(ports_num+1)-1:0] data_i_t;
  // output data
  wire                                             wr_req_t;
  wire                               [ports_num:0] in_w_t;
  wire                     [data_size+addr_size:0] data_o_t;
  // output expected data
  reg                                              wr_req_exp;
  reg                                [ports_num:0] in_w_exp;
  reg                      [data_size+addr_size:0] data_o_exp;

  receiver #(
    .DATA_SIZE(data_size),
    .ADDR_SIZE(addr_size),
    .PORTS_NUM(ports_num)
  ) test_recv (
    .clk    ( clk_r     ),
    .a_rst  ( rst_t     ),
    .is_full( is_full_t ),
    .in_r   ( in_r_t    ),
    .data_i ( data_i_t  ),
    .wr_req ( wr_req_t  ),
    .in_w   ( in_w_t    ),
    .data_o ( data_o_t  )
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
      $readmemb(`TESTFILE, test_data);
      rst_t = 1'b1;
    end

  always @(posedge clk_r)
    {rst_t, is_full_t, in_r_t, data_i_t, wr_req_exp, in_w_exp, data_o_exp} = test_data[test_idx];

  always @(posedge clk_r)
    begin
      #(period/4); // waiting for changing
      $display("%4d Output  : state = %d, wr_req = %b, in_w = %b, data_o = %b\n", test_idx, test_recv.state, wr_req_t, in_w_t, data_o_t);
      if (wr_req_exp !== wr_req_t || in_w_exp !== in_w_t || data_o_exp !== data_o_t)
        begin
          $display("Error, expected: wr_req = %b, in_w = %b, data_o = %b\n", wr_req_exp, in_w_exp, data_o_exp);
          errors_num = errors_num + 1;
        end
      test_idx = test_idx + 1;
      if (test_idx == max_test || test_data[test_idx] === {test_size{1'bx}})
        begin
          $display("Finish: %d tests, %d errors\n", test_idx, errors_num);
          $finish;
        end
    end
endmodule // receiver_tb