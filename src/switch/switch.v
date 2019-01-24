module switch #(
  parameter DATA_SIZE = 32,
  parameter ADDR_SIZE = 4,
  parameter PORTS_NUM = 4,
  parameter NODES_NUM = 9,
  parameter ADDR      = 0,
  parameter MEM_LOG2  = 5,
  localparam BUS_SIZE = DATA_SIZE + ADDR_SIZE + 1
) (
  input                               clk   ,
  input                               a_rst ,
  input                 [PORTS_NUM:0] wr_ready_in  ,
  input                 [PORTS_NUM:0] r_ready_in ,
  input  [BUS_SIZE*(PORTS_NUM+1)-1:0] data_i,
  output                [PORTS_NUM:0] r_ready_out  ,
  output                [PORTS_NUM:0] wr_ready_out ,
  output [BUS_SIZE*(PORTS_NUM+1)-1:0] data_o
);

  wire is_full;
  wire wr_req;
  wire mem_readed;
  wire is_empty;
  wire wr_en;
  wire [BUS_SIZE-1:0] to_mem;
  wire [BUS_SIZE-1:0] from_mem;

  receiver #(
    .DATA_SIZE(DATA_SIZE),
    .ADDR_SIZE(ADDR_SIZE),
    .PORTS_NUM(PORTS_NUM)
  ) recv (
    .clk    (clk),
    .a_rst  (a_rst),
    .is_full(is_full),
    .wr_ready_in   (wr_ready_in),
    .data_i (data_i),
    .wr_req (wr_req),
    .r_ready_out   (r_ready_out),
    .data_o (to_mem)
  );

  queue #(
    .BUS_SIZE(BUS_SIZE),
    .PTR_SIZE(MEM_LOG2)
  ) memory (
    .clk   (clk),
    .a_rst (a_rst),
    .wr_req(wr_req),
    .mem_readed(mem_readed),
    .data_i(to_mem),
    .full  (is_full),
    .empty (is_empty),
    .data_o(from_mem)
  );

  transceiver #(
    .ADDR     (ADDR),
    .DATA_SIZE(DATA_SIZE),
    .ADDR_SIZE(ADDR_SIZE),
    .PORTS_NUM(PORTS_NUM),
    .NODES_NUM(NODES_NUM)
  ) trans (
    .clk   (clk),
    .a_rst (a_rst),
    .mem_empty(is_empty),
    .r_ready_in (r_ready_in),
    .data_i(from_mem),
    .mem_readed(mem_readed),
    .wr_ready_out (wr_ready_out),
    .data_o(data_o)
  );
endmodule

module sw_to_connector #(
  parameter FLIT_SIZE = 37,
  parameter PORTS_NUM = 4,
  localparam PORT_SIZE = (FLIT_SIZE + 2)
)(
  input            [PORTS_NUM-1:0] r_ready_out   ,
  input            [PORTS_NUM-1:0] wr_ready_out  ,
  input  [FLIT_SIZE*PORTS_NUM-1:0] sw_data,
  output [PORT_SIZE*PORTS_NUM-1:0] bus
);
  genvar i;
  generate
    for (i = 0; i < PORTS_NUM; i = i + 1)
      assign bus[i*PORT_SIZE+:PORT_SIZE] = {sw_data[i*FLIT_SIZE+:FLIT_SIZE], r_ready_out[i], wr_ready_out[i]};
  endgenerate
endmodule // sw_to_connector

module connector_to_sw #(
  parameter FLIT_SIZE = 37,
  parameter PORTS_NUM = 4,
  localparam PORT_SIZE = (FLIT_SIZE + 2)
)(
  input  [PORT_SIZE*PORTS_NUM-1:0] bus   ,
  output           [PORTS_NUM-1:0] wr_ready_in  ,
  output           [PORTS_NUM-1:0] r_ready_in ,
  output [FLIT_SIZE*PORTS_NUM-1:0] sw_data
);
  genvar i;
  generate
    for (i = 0; i < PORTS_NUM; i = i + 1)
      assign {sw_data[i*FLIT_SIZE+:FLIT_SIZE], r_ready_in[i], wr_ready_in[i]} = bus[i*PORT_SIZE+:PORT_SIZE];
  endgenerate
endmodule // connector_to_sw
