`timescale 1ns / 1ns
`define RT_PATH "../testfiles/mesh2d_rt.hex" // path to the routing table

module switch_tb();
  
  localparam period   = 2;
  localparam max_test = 1000;
  localparam addr_size = 2;
  localparam data_size = 8;
  localparam ports_num = 4;
  localparam bus_size = addr_size + data_size + 1;

  integer test_idx;

  reg clk_r;
  reg rst_r;

  wire [ports_num:0] ip_r_ready_out;
  wire [ports_num:0] ip_wr_ready_out;
  wire [ports_num:0] sw_r_ready_out;
  wire [ports_num:0] sw_wr_ready_out;
  wire [(ports_num+1)*bus_size-1:0] ip_data_o;
  wire [(ports_num+1)*bus_size-1:0] sw_data_o;

  //connect 2 ip to 1 switch
    switch #(
    .DATA_SIZE(data_size),
    .ADDR_SIZE(addr_size),
    .PORTS_NUM(ports_num),
    .NODES_NUM(4),
    .ADDR(0),
    .MEM_LOG2(5)
  ) sw (
    .clk   (clk_r),
    .a_rst (rst_r),
    .wr_ready_in  (ip_wr_ready_out),
    .r_ready_in (ip_r_ready_out),
    .data_i(ip_data_o),
    .r_ready_out  (sw_r_ready_out),
    .wr_ready_out (sw_wr_ready_out),
    .data_o(sw_data_o)
  );

  genvar i;
  generate // generating IPs with 1 and 2 addresses
    for (i = 1; i < 3; i = i + 1)
      fabric #(
        .DATA_SIZE(data_size),
        .ADDR_SIZE(addr_size),
        .ADDR(i),
        .NODES_NUM(3),
        .PACKS_TO_GEN(10),
        .MAX_PACK_LEN(10),
        .DEBUG(1)
      ) IP (
        .clk      (clk_r),
        .a_rst    (rst_r),
        .data_i   (sw_data_o[(i-1)*bus_size+:bus_size]),
        .data_o   (ip_data_o[(i-1)*bus_size+:bus_size]),
        .r_ready_in    (sw_r_ready_out[i-1]),
        .wr_ready_in     (sw_wr_ready_out[i-1]),
        .wr_ready_out    (ip_wr_ready_out[i-1]),
        .r_ready_out     (ip_r_ready_out[i-1])
      );
  endgenerate

  // local ip
  fabric #(
    .DATA_SIZE(data_size),
    .ADDR_SIZE(addr_size),
    .ADDR(0),
    .NODES_NUM(3),
    .PACKS_TO_GEN(10),
    .MAX_PACK_LEN(10),
    .DEBUG(1)
  ) Local_IP (
    .clk      (clk_r),
    .a_rst    (rst_r),
    .data_i   (sw_data_o[4*bus_size+:bus_size]),
    .data_o   (ip_data_o[4*bus_size+:bus_size]),
    .r_ready_in    (sw_r_ready_out[4]),
    .wr_ready_in     (sw_wr_ready_out[4]),
    .wr_ready_out    (ip_wr_ready_out[4]),
    .r_ready_out     (ip_r_ready_out[4])
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
endmodule // switch_tb