module queue #(
  parameter BUS_SIZE  = 32,
  parameter PTR_SIZE   = 5
) (
  input                     clk,
  input                     a_rst,
  input                     wr_req,
  input                     readed,
  input      [BUS_SIZE-1:0] data_i,
  output                    full,
  output                    empty,
  output     [BUS_SIZE-1:0] data_o
);
  // pointers
  reg [PTR_SIZE-1:0] wr_ptr;
  reg [PTR_SIZE-1:0] r_ptr;
  reg [  PTR_SIZE:0] filling;

  // memory
  reg [BUS_SIZE-1:0] mem [2**PTR_SIZE-1:0];

  //status assigns
  assign full  = (filling === {1'b1, {PTR_SIZE{1'b0}}});
  assign empty = (filling === {PTR_SIZE + 1{1'b0}});
  assign data_o = mem[r_ptr]; // async reading

  integer i;
  initial
    for (i = 0; i < 2**PTR_SIZE; i = i + 1)
      mem[i] = {BUS_SIZE{1'b0}};
  
  always @(posedge clk, posedge a_rst)
    if (a_rst)
      begin
        wr_ptr  <= {PTR_SIZE{1'b0}};
        r_ptr   <= {PTR_SIZE{1'b0}};
        filling <= {PTR_SIZE+1{1'b0}};
      end
    else
      begin
        if (wr_req & ~full)
          begin
            mem[wr_ptr] = data_i;
            wr_ptr = wr_ptr + 1;
            filling = filling + 1;
          end
        if (readed)
          begin
            r_ptr = r_ptr + 1;
            filling = filling - 1;
          end
      end
endmodule // fifo