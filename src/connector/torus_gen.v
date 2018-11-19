module torus #(
  parameter H_SIZE = 3,
  parameter PORT_SIZE = (37+2),
  parameter NODES_NUM = 2
) (
  input  [NODES_NUM*4*PORT_SIZE-1:0] data_i,
  output [NODES_NUM*4*PORT_SIZE-1:0] data_o
);
  genvar i, j;
  generate
    for ( i = 0; i < NODES_NUM; i = i + 1 ) // input index
      for ( j = i + 1; j < NODES_NUM; j = j + 1 ) // output index
        if ( ( j == i + 1 ) & ( j % H_SIZE != 0 ) ) // port 0 to 2
          begin
            assign data_o [i*4*PORT_SIZE+0*PORT_SIZE+:PORT_SIZE] = data_i [j*4*PORT_SIZE + 2*PORT_SIZE+:PORT_SIZE];
            assign data_o [j*4*PORT_SIZE+2*PORT_SIZE+:PORT_SIZE] = data_i [i*4*PORT_SIZE + 0*PORT_SIZE+:PORT_SIZE];
          end
        else if ( (j == i + 2) & ( i % H_SIZE == 0) ) // port 2 to 0
          begin
            assign data_o [j*4*PORT_SIZE+0*PORT_SIZE+:PORT_SIZE] = data_i [i*4*PORT_SIZE + 2*PORT_SIZE+:PORT_SIZE];
            assign data_o [i*4*PORT_SIZE+2*PORT_SIZE+:PORT_SIZE] = data_i [j*4*PORT_SIZE + 0*PORT_SIZE+:PORT_SIZE];
          end
        else if (j == ( H_SIZE + i )) // port 1 to 3
          begin
            assign data_o [i*4*PORT_SIZE+1*PORT_SIZE+:PORT_SIZE] = data_i [j*4*PORT_SIZE + 3*PORT_SIZE+:PORT_SIZE];
            assign data_o [j*4*PORT_SIZE+3*PORT_SIZE+:PORT_SIZE] = data_i [i*4*PORT_SIZE + 1*PORT_SIZE+:PORT_SIZE];
          end
        else if ( (j - i) == (NODES_NUM - H_SIZE) ) // port 3 to 1
          begin
            assign data_o [j*4*PORT_SIZE+1*PORT_SIZE+:PORT_SIZE] = data_i [i*4*PORT_SIZE + 3*PORT_SIZE+:PORT_SIZE];
            assign data_o [i*4*PORT_SIZE+3*PORT_SIZE+:PORT_SIZE] = data_i [j*4*PORT_SIZE + 1*PORT_SIZE+:PORT_SIZE];
          end
  endgenerate
endmodule