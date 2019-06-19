`include "../../src/connector/add_ops.vh"

module circulant_2 #(
  parameter S0 = 1,
  parameter S1 = 2,
  parameter PORT_SIZE = (37+2),
  parameter NODES_NUM = 2
) (
  input  [NODES_NUM*4*PORT_SIZE-1:0] data_i,
  output [NODES_NUM*4*PORT_SIZE-1:0] data_o
);
  genvar i;
  generate
    for ( i = 0; i < NODES_NUM; i = i + 1 ) //  input router index
      begin : connections
      // step 0
        assign data_o [`ADD_MOD(i, S0, NODES_NUM)*4*PORT_SIZE+3*PORT_SIZE+:PORT_SIZE] = data_i [i*4*PORT_SIZE+0*PORT_SIZE+:PORT_SIZE];
        assign data_o [`SUB_MOD(i, S0, NODES_NUM)*4*PORT_SIZE+0*PORT_SIZE+:PORT_SIZE] = data_i [i*4*PORT_SIZE+3*PORT_SIZE+:PORT_SIZE];

        // step 1
        assign data_o [`ADD_MOD(i, S1, NODES_NUM)*4*PORT_SIZE+2*PORT_SIZE+:PORT_SIZE] = data_i [i*4*PORT_SIZE+1*PORT_SIZE+:PORT_SIZE];       
        assign data_o [`SUB_MOD(i, S1, NODES_NUM)*4*PORT_SIZE+1*PORT_SIZE+:PORT_SIZE] = data_i [i*4*PORT_SIZE+2*PORT_SIZE+:PORT_SIZE];
      end
  endgenerate
endmodule // circulant_2