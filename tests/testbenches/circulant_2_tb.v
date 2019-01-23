`timescale 1ns / 1ps
`define TESTFILE "../testfiles/circ2_tf.bin"

module circulant_2_tb();
  localparam                 period = 100;
  // testing module params
  localparam                 bus_size = 4;
  localparam                 ports_num = 4;
  // parameters for test data
  localparam                 tests_num = 4*(4+6+2*9);
  localparam                 input_data_num = 0;
  localparam                 exp_data_num = 3;
  // test_len must be a max data sequence len (may be input or output)
  localparam                 max_test_len = 9*ports_num*bus_size;

  reg                        clk_r;
  // test data regs
  reg     [max_test_len-1:0] test_data [(input_data_num+exp_data_num)*tests_num-1:0];
  integer                    test_idx;
  integer                    exp_idx;
  integer                    out_idx;
  integer                    errors_num;

  // input regs
  reg     [9*ports_num*bus_size-1:0] test_data_i;           
  reg     [9*ports_num-1:0]          test_r_ready_out;
  reg     [9*ports_num-1:0]          test_wr_ready_out;
  // output wires
  wire    [9*ports_num*bus_size-1:0] test_data_o [3:0];
  wire    [9*ports_num-1:0]          test_r_ready_in  [3:0];
  wire    [9*ports_num-1:0]          test_wr_ready_in   [3:0];
  // expected outputs 
  wire    [9*ports_num*bus_size-1:0] exp_data_o;           
  wire    [9*ports_num-1:0]          exp_r_ready_in;
  wire    [9*ports_num-1:0]          exp_wr_ready_in;

  topology_module #(
    .BUS_SIZE     ( bus_size ), 
    .NODES_NUM    ( 4 ), 
    .S0           ( 1 ),
    .S1           ( 2 )
  ) circulant_4_1_2 (
    .data_i       ( test_data_i[4*ports_num*bus_size-1:0]    ),
    .r_ready_out_i       ( test_r_ready_out[4*ports_num-1:0]               ),
    .wr_ready_out_i      ( test_wr_ready_out[4*ports_num-1:0]              ),

    .data_o       ( test_data_o[0][4*ports_num*bus_size-1:0] ),
    .r_ready_in_o      ( test_r_ready_in[0][4*ports_num-1:0]           ),
    .wr_ready_in_o       ( test_wr_ready_in[0][4*ports_num-1:0]            )
  );

  topology_module #(
    .BUS_SIZE     ( bus_size ), 
    .NODES_NUM    ( 6 ), 
    .S0           ( 1 ),
    .S1           ( 2 )
  ) circulant_6_2_1 (
    .data_i       ( test_data_i[6*ports_num*bus_size-1:0]    ),
    .r_ready_out_i       ( test_r_ready_out[6*ports_num-1:0]               ),
    .wr_ready_out_i      ( test_wr_ready_out[6*ports_num-1:0]              ),

    .data_o       ( test_data_o[1][6*ports_num*bus_size-1:0] ),
    .r_ready_in_o      ( test_r_ready_in[1][6*ports_num-1:0]           ),
    .wr_ready_in_o       ( test_wr_ready_in[1][6*ports_num-1:0]            )
  );

  topology_module #(
    .BUS_SIZE     ( bus_size ), 
    .NODES_NUM    ( 9 ), 
    .S0           ( 1 ),
    .S1           ( 2 )
  ) circulant_9_2_1 (
    .data_i       ( test_data_i[9*ports_num*bus_size-1:0]    ),
    .r_ready_out_i       ( test_r_ready_out[9*ports_num-1:0]               ),
    .wr_ready_out_i      ( test_wr_ready_out[9*ports_num-1:0]              ),

    .data_o       ( test_data_o[2][9*ports_num*bus_size-1:0] ),
    .r_ready_in_o      ( test_r_ready_in[2][9*ports_num-1:0]           ),
    .wr_ready_in_o       ( test_wr_ready_in[2][9*ports_num-1:0]            )
  );

  topology_module #(
    .BUS_SIZE     ( bus_size ), 
    .NODES_NUM    ( 9 ), 
    .S0           ( 2 ),
    .S1           ( 3 )
  ) circulan_9_2_3 (
    .data_i       ( test_data_i[9*ports_num*bus_size-1:0]    ),
    .r_ready_out_i       ( test_r_ready_out[9*ports_num-1:0]               ),
    .wr_ready_out_i      ( test_wr_ready_out[9*ports_num-1:0]              ),

    .data_o       ( test_data_o[3][9*ports_num*bus_size-1:0] ),
    .r_ready_in_o      ( test_r_ready_in[3][9*ports_num-1:0]           ),
    .wr_ready_in_o       ( test_wr_ready_in[3][9*ports_num-1:0]            )
  );

  // clock signal generating
  initial
    begin
      clk_r = 1'b0;
      forever
        #(period/2) clk_r = ~clk_r;
    end

  // init regs and read test data
  initial
    begin
      test_data_i = {{max_test_len-ports_num{1'b0}}, {bus_size{1'b1}}};
      test_r_ready_out = {{8*ports_num+ports_num-1{1'b0}}, 1'b1};
      test_wr_ready_out = {{8*ports_num+ports_num-1{1'b0}}, 1'b1};
      test_idx = 0;
      out_idx = 0;
      exp_idx = 0;
      errors_num = 0;
      $readmemb(`TESTFILE, test_data);
      $display("Test file has been read");
    end

  // dump
  initial
    begin
      $dumpfile("dumps/circ2_tb.vcd");
      $dumpvars;
    end

  // out data
  assign exp_data_o = test_data[test_idx*exp_data_num];
  assign exp_r_ready_in = test_data[test_idx*exp_data_num + 1];
  assign exp_wr_ready_in = test_data[test_idx*exp_data_num + 2];

  // test data input and processing
  always @( posedge clk_r )  // setting input regs on a negative edge
    begin
      #(period/4);
      // in data
      test_data_i = test_data_i <<< bus_size;
      test_r_ready_out = test_r_ready_out <<< 1;
      test_wr_ready_out = test_wr_ready_out <<< 1;
      // module idx
      case (test_idx)
        4*4:  begin
          out_idx = 1;
          test_data_i = {{max_test_len-ports_num{1'b0}}, {bus_size{1'b1}}};
          test_r_ready_out = {{8*ports_num+ports_num-1{1'b0}}, 1'b1};
          test_wr_ready_out = {{8*ports_num+ports_num-1{1'b0}}, 1'b1};
        end
        4*(4+6): begin
          out_idx = 2;
          test_data_i = {{max_test_len-ports_num{1'b0}}, {bus_size{1'b1}}};
          test_r_ready_out = {{8*ports_num+ports_num-1{1'b0}}, 1'b1};
          test_wr_ready_out = {{8*ports_num+ports_num-1{1'b0}}, 1'b1};
        end
        4*(4+6+9): begin
          out_idx = 3;
          test_data_i = {{max_test_len-ports_num{1'b0}}, {bus_size{1'b1}}};
          test_r_ready_out = {{8*ports_num+ports_num-1{1'b0}}, 1'b1};
          test_wr_ready_out = {{8*ports_num+ports_num-1{1'b0}}, 1'b1};
        end
      endcase
    end
  
  // 
  always @( posedge clk_r )  // then executing on posedge
    begin
      // end of tests, the vector is undefined
      if ( test_idx == tests_num*9 & out_idx == tests_num || test_data[test_idx*exp_data_num] === {max_test_len{1'bx}} )
        begin
          $display("%d tests completed with %d errors", test_idx, errors_num);
          $finish;
        end
      // checking if outs are expected
      if ( test_data_o[out_idx] !== exp_data_o || test_r_ready_in[out_idx] !== exp_r_ready_in || test_wr_ready_in[out_idx] !== exp_wr_ready_in )
        begin
          $display("Error in %d test", test_idx);
          $display("Output:   %b, %b, %b\nExpected: %b, %b, %b", test_data_o[out_idx], test_r_ready_in[out_idx], test_wr_ready_in[out_idx],
                                                                 exp_data_o,           exp_r_ready_in,           exp_wr_ready_in);
          errors_num = errors_num + 1;
        end
      test_idx = test_idx + 1;
    end

endmodule // circulant_2_tb