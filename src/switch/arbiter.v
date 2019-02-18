module arbiter #(
  parameter PORTS_NUM = 4,
  parameter NODES_NUM = 4,
  parameter ADDR = 0,
  parameter RT_PATH = ""
) (
  input clk,
  input a_rst,
  
  input [PORTS_NUM:0] wr_ready_in,
  input [PORTS_NUM:0] r_ready_in,
  input mem_is_full,
  input mem_is_empty,
  output reg [PORTS_NUM:0] r_ready_out,
  output reg [PORTS_NUM:0] wr_ready_out,
  output reg wr_req,
  output reg in_port,
  output reg out_port
);
  
endmodule