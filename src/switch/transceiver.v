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

  output reg                              readed,
  output reg [PORTS_NUM:0]                wr_ready_out,
  output reg [BUS_SIZE*(PORTS_NUM+1)-1:0] data_o
);

  localparam RESET = 2'h0, 
             WAIT  = 2'h1,
             SEND  = 2'h2,
             END   = 2'h3; 
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
    readed = 1'b0;
    if (a_rst) state = RESET;
    case (state)
    RESET:
    begin
      wr_ready_out  = {PORTS_NUM+1{1'b0}};
      port_r = PORTS_NUM; // default will send to itself
      state  = WAIT;
    end
    WAIT:
      if (!mem_empty)  // when queue has flit to send
      begin
        // if connected save port num, else PORTS_NUM to send back
        port_r = (r_ready_in[port] !== 1'bz) ? port : PORTS_NUM;
        state = SEND;
      end
    SEND:
    begin
      data_o[port_r*BUS_SIZE+:BUS_SIZE] = data_i;
      wr_ready_out [port_r]             = 1'b1;
      readed                            = 1'b1;
      state                             = END;
    end
    END:
      if (r_ready_in[port_r] === 1'b1) // if readed from transciever
      begin
        wr_ready_out[port_r] = 1'b0;
        port_r = PORTS_NUM;
        state  = WAIT;         // waiting another flit
      end
    default: state = RESET;
    endcase
  end
endmodule
