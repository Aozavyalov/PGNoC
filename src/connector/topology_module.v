module topology_module #(
  parameter PORT_SIZE = 37+2,
  parameter PORTS_NUM = 4,
  parameter NODES_NUM = 2,
  `ifdef MESH_2D
  parameter H_SIZE = 2
  `else
  `ifdef CIRCULANT_2
  parameter S0 = 1,
  parameter S1 = 2
  `else
  `ifdef TORUS
  parameter H_SIZE = 2
  `endif // TORUS
  `endif // CIRCULANT_2
  `endif // MESH
)(
  input  [NODES_NUM*PORTS_NUM*PORT_SIZE-1:0] data_i,
  output [NODES_NUM*PORTS_NUM*PORT_SIZE-1:0] data_o
);
  `ifdef MESH_2D
  mesh_2d #(.PORT_SIZE(PORT_SIZE), .NODES_NUM(NODES_NUM), .H_SIZE(H_SIZE)) connector(data_i, data_o);
  `else
  `ifdef CIRCULANT_2
  circulant_2 #(.PORT_SIZE(PORT_SIZE), .NODES_NUM(NODES_NUM), .S0(S0), .S1(S1)) connector(data_i, data_o);
  `else
  `ifdef TORUS
  torus #(.PORT_SIZE(PORT_SIZE), .NODES_NUM(NODES_NUM), .H_SIZE(H_SIZE)) connector(data_i, data_o);
  `endif // TORUS
  `endif // CIRCULANT_2
  `endif // MESH

endmodule // topology_module