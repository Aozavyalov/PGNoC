module torus #(
  parameter H_SIZE = 3,
  parameter PORT_SIZE = (37+2),
  parameter NODES_NUM = 2
) (
  input  [NODES_NUM*4*PORT_SIZE-1:0] data_i,
  output [NODES_NUM*4*PORT_SIZE-1:0] data_o
);
  genvar sw_src, sw_dst;
  generate
    for ( sw_src = 0; sw_src < NODES_NUM; sw_src = sw_src + 1 ) // input index
      for ( sw_dst = 0; sw_dst < NODES_NUM; sw_dst = sw_dst + 1 ) // output index
        if (((sw_dst == sw_src + 1) && (sw_src % H_SIZE != H_SIZE - 1)) || ((sw_src % H_SIZE == H_SIZE - 1) && (sw_src-sw_dst-H_SIZE+1 == 0)))    
        begin
          assign data_o [sw_src*4*PORT_SIZE+0*PORT_SIZE+:PORT_SIZE] = data_i [sw_dst*4*PORT_SIZE + 2*PORT_SIZE+:PORT_SIZE];
          assign data_o [sw_dst*4*PORT_SIZE+2*PORT_SIZE+:PORT_SIZE] = data_i [sw_src*4*PORT_SIZE + 0*PORT_SIZE+:PORT_SIZE];
        end
        else if ((sw_dst == sw_src + H_SIZE) || (NODES_NUM - sw_src + sw_dst == H_SIZE))
        begin
          assign data_o [sw_src*4*PORT_SIZE+1*PORT_SIZE+:PORT_SIZE] = data_i [sw_dst*4*PORT_SIZE + 3*PORT_SIZE+:PORT_SIZE];
          assign data_o [sw_dst*4*PORT_SIZE+3*PORT_SIZE+:PORT_SIZE] = data_i [sw_src*4*PORT_SIZE + 1*PORT_SIZE+:PORT_SIZE];
        end
  endgenerate
endmodule