module mesh_2d #(
  parameter H_SIZE = 1,
  parameter PORT_SIZE = (37+2),
  parameter NODES_NUM = 2
) (
  input  [NODES_NUM*4*PORT_SIZE-1:0] data_i,
  output [NODES_NUM*4*PORT_SIZE-1:0] data_o
);
  genvar i, j;
  generate
    begin
    for ( i = 0; i < NODES_NUM; i = i + 1 )
      for ( j = i; j < NODES_NUM; j = j + 1 )
        if ( ( j == i + 1 ) && ( j % H_SIZE != 0 ) ) // horizontal connections
          begin
            assign data_o [i*4*PORT_SIZE+0*PORT_SIZE+:PORT_SIZE] = data_i [j*4*PORT_SIZE + 2*PORT_SIZE+:PORT_SIZE];
            assign data_o [j*4*PORT_SIZE+2*PORT_SIZE+:PORT_SIZE] = data_i [i*4*PORT_SIZE + 0*PORT_SIZE+:PORT_SIZE];
          end
        else if ( j == H_SIZE + i ) // vertical connections
          begin
            assign data_o [i*4*PORT_SIZE+1*PORT_SIZE+:PORT_SIZE] = data_i [j*4*PORT_SIZE + 3*PORT_SIZE+:PORT_SIZE];
            assign data_o [j*4*PORT_SIZE+3*PORT_SIZE+:PORT_SIZE] = data_i [i*4*PORT_SIZE + 1*PORT_SIZE+:PORT_SIZE];
          end
    end
  endgenerate
endmodule