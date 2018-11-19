`timescale 1ns / 1ns
`ifndef TESTFILE
`define TESTFILE "../testfiles/transceiver_tf.bin"
`endif
`define RT_PATH "../testfiles/mesh2d_rt.hex"

module transceiver_tb();

  localparam period    = 4;
  localparam max_test  = 50;
  localparam data_size = 4;
  localparam addr_size = 1;
  localparam ports_num = 4;
  localparam bus_size  = data_size+addr_size+1;
  localparam test_size = 3 + 2*(ports_num + 1) + bus_size*(ports_num + 1) + bus_size;

  reg clk_r;

  // module connections
  // input data
  reg                               rst_t; 
  reg                               is_empty_t;
  reg                 [ports_num:0] out_w_t;
  reg                [bus_size-1:0] data_i_t;
  // output data
  wire                              r_req_t;
  wire                [ports_num:0] out_r_t;
  wire [bus_size*(ports_num+1)-1:0] data_o_t;
  // output expected data
  reg                               r_req_exp;
  reg                 [ports_num:0] out_r_exp;
  reg  [bus_size*(ports_num+1)-1:0] data_o_exp;

  transceiver #(
    .DATA_SIZE(4),
    .ADDR_SIZE(1),
    .NODES_NUM(4)
  ) test_trans (
    .clk   (clk_r),
    .a_rst (rst_t),
    .empty (is_empty_t),
    .out_w (out_w_t),
    .data_i(data_i_t),
    .r_req (r_req_t),
    .out_r (out_r_t),
    .data_o(data_o_t)
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
    {rst_t, is_empty_t, out_w_t, data_i_t, r_req_exp, out_r_exp, data_o_exp} = test_data[test_idx];

  always @(posedge clk_r)
    begin
      #(period/4); // waiting for changing
      $display("%4d Output  : state = %d, r_req = %b, out_r = %b, data_o = %b\n", test_idx, test_trans.state, r_req_t, out_r_t, data_o_t);
      if (r_req_exp !== r_req_t || out_r_exp !== out_r_t || data_o_exp !== data_o_t)
        begin
          $display("Error, expected: r_req = %b, out_r = %b, data_o = %b\n", r_req_exp, out_r_exp, data_o_exp);
          errors_num = errors_num + 1;
        end
      test_idx = test_idx + 1;
      if (test_idx == max_test || test_data[test_idx] === {test_size{1'bx}})
        begin
          $display("Finish: %d tests, %d errors\n", test_idx, errors_num);
          $finish;
        end
    end
endmodule // transceiver_tb
