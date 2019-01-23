module receiver #(
  parameter DATA_SIZE  = 32,
  parameter ADDR_SIZE  = 4,
  parameter PORTS_NUM  = 4,
  localparam BUS_SIZE  = DATA_SIZE + ADDR_SIZE + 1
)(
  input                               clk,
  input                               a_rst,

  input                               is_full,
  input  [               PORTS_NUM:0] wr_ready_in,
  input  [(PORTS_NUM+1)*BUS_SIZE-1:0] data_i,

  output reg                          wr_req,
  output reg [           PORTS_NUM:0] r_ready_out,
  output reg [          BUS_SIZE-1:0] data_o
);
  // states
  localparam RESET  = 2'h0,
             SEARCH = 2'h1,
             WRITE  = 2'h2,
             END    = 2'h3;
  reg [1:0] state;
  reg [3:0] port;
  integer i;

  always @(posedge clk, posedge a_rst)
    begin
      // data_o = data_i[port*BUS_SIZE+:BUS_SIZE];
      r_ready_out   = {PORTS_NUM+1{1'b0}};
      wr_req = 1'b0;
      if (a_rst)
        state = RESET;
      case (state)
        RESET: 
          begin
            state  <= SEARCH;
            port   <= PORTS_NUM;
          end
        SEARCH:
          begin
            if (!is_full)
              for (i = 0; (i < PORTS_NUM + 1) & state == SEARCH; i = i + 1)
                if (wr_ready_in[port] === 1'b1)
                  state = WRITE;
                else
                  port = port + 1'b1;
          end
        WRITE:
          begin
            if (wr_ready_in[port] === 1'b1 & !is_full)
              begin
                r_ready_out[port] = 1'b1;
                wr_req     = 1'b1;
                data_o     = data_i[port*BUS_SIZE+:BUS_SIZE];
                state      = END;
              end
          end
        END:
          begin
            if (data_o[ADDR_SIZE] == 1'b1)
              state <= SEARCH;
            else
              state <= WRITE;
          end
        default:
          state <= RESET;
      endcase
    end

endmodule // input