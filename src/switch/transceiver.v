module transceiver #(
  parameter ADDR         = 0,
  parameter DATA_SIZE  = 32,
  parameter ADDR_SIZE  = 4,
  parameter PORTS_NUM  = 4,
  parameter NODES_NUM  = 9,
  localparam BUS_SIZE  = DATA_SIZE + ADDR_SIZE + 1
) (
  input                                   clk,
  input                                   a_rst,
  input                                   mem_empty,
  input      [PORTS_NUM:0]                r_ready_in,
  input      [BUS_SIZE-1:0]               data_i,

  output reg                              mem_readed,
  output reg [PORTS_NUM:0]                wr_ready_out,
  output reg [BUS_SIZE*(PORTS_NUM+1)-1:0] data_o
);

  localparam RESET = 2'h0, 
             WAIT_PCKG  = 2'h1,
             SEND_FLIT  = 2'h2,
             ACCEPTING  = 2'h3; 
  reg [1:0] state;

  wire [ADDR_SIZE-1:0] dest_addr;
  wire [3:0] port;
  reg  [3:0] port_r;

  assign dest_addr = data_i[ADDR_SIZE-1:0];

  routing_module #(
    .NODES_NUM(NODES_NUM),
    .ADDR_SIZE(ADDR_SIZE),
    .ADDR     (ADDR),
    .PORTS_NUM(PORTS_NUM)
  ) rt (
    .dest_sw (dest_addr),
    .port_num(port)
  );

  always @(posedge clk, posedge a_rst) begin
    mem_readed = 1'b0;
    if (a_rst) state = RESET;
    case (state)
    RESET:
    begin
      wr_ready_out  = {PORTS_NUM+1{1'b0}};
      port_r = PORTS_NUM; // default will SEND_FLIT to itself
      state  = WAIT_PCKG;
    end
    WAIT_PCKG:
      if (!mem_empty)  // when queue has flit to SEND_FLIT
      begin
        // if connected save port num, else PORTS_NUM to SEND_FLIT back
        port_r = (r_ready_in[port] !== 1'bz) ? port : PORTS_NUM;
        state = SEND_FLIT;
      end
    SEND_FLIT:
      if (!mem_empty)  // when queue has flit to SEND_FLIT
      begin
        data_o[port_r*BUS_SIZE+:BUS_SIZE] = data_i;
        wr_ready_out [port_r]             = 1'b1;
        mem_readed                        = 1'b1;
        state                             = ACCEPTING;
      end
    ACCEPTING:
      if (r_ready_in[port_r] === 1'b1) // if mem_readed from transciever
      begin
        wr_ready_out[port_r] = 1'b0;
        state = (data_o[ADDR_SIZE] == 1) ? WAIT_PCKG : SEND_FLIT;
      end
    default: state = RESET;
    endcase
  end
endmodule
