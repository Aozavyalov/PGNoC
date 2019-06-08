module routing_module #(
  parameter NODES_NUM = 9,
  parameter ADDR_SIZE = 4,
  parameter ADDR      = 0,
  parameter PORTS_NUM = 4,
  parameter RT_PATH   = ""
) (
  input  [ADDR_SIZE-1:0] dest_sw,
  output [3:0] port_num
);

reg [NODES_NUM*4-1:0] rout_table [NODES_NUM-1:0];

initial
  $readmemh(RT_PATH, rout_table);

assign port_num = rout_table[ADDR][dest_sw*4+:4];

endmodule
