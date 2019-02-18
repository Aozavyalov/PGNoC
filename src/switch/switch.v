module switch #(
  parameter DATA_SIZE = 32,
  parameter ADDR_SIZE = 4,
  parameter PORTS_NUM = 4,
  parameter NODES_NUM = 9,
  parameter ADDR      = 0,
  parameter MEM_LOG2  = 5,
  parameter RT_PATH   = "",
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

  wire [31:0] in_port, out_port;

  arbiter #(
    .PORTS_NUM(PORTS_NUM),
    .NODES_NUM(NODES_NUM),
    .ADDR(ADDR),
    .RT_PATH(RT_PATH)
  ) control (
    .clk(clk),
    .a_rst(a_rst),
    // switch inputs
    .wr_ready_in(wr_ready_in),
    .r_ready_in(r_ready_in),
    // switch outputs
    .r_ready_out(r_ready_out),
    .wr_ready_out(wr_ready_out),
    // memory signals
    .mem_is_full(is_full),
    .mem_is_empty(is_empty),
    .wr_req(wr_req),
    // control signals
    .in_port(in_port),
    .out_port(out_port)
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

  integer i, j;
  always @(*)
  begin : input_select
    for (i = 0; i < PORTS_NUM + 1; i = i + 1)
      if (i == in_port)
        to_mem = data_i[i*BUS_SIZE+:BUS_SIZE];
  end // input_select

  always @(*)
  begin : output_select
    for (j = 0; j < PORTS_NUM + 1; j = j + 1)
      if (j == out_port)
        data_o[j*BUS_SIZE+:BUS_SIZE] = from_mem;
  end // output_select

endmodule
