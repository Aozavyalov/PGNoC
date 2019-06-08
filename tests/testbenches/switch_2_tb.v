`timescale 1ns / 1ns

module switch_2_tb();
  
	localparam period   = 2;
	localparam max_test = 2000;

	integer test_idx;

	reg clk_r;
	reg rst_r;

  wire 

  fabric #(
    .DATA_SIZE(4),
    .ADDR_SIZE(1),
    .ADDR(0),
    .NODES_NUM(2),
    .PACKS_TO_GEN(10),
    .MAX_PACK_LEN(10)
  ) IP0 (
    .clk      (clk_r),
    .a_rst    (rst_r),
    .data_i   (data_ip_in [i]),
    .data_o   (data_ip_out[i]),
    .r_ready_in    (r_ready_in_ip_sw[i]),
    .wr_ready_in     (wr_ready_in_ip_sw [i]),
    .wr_ready_out    (wr_ready_out_ip_sw[i]),
    .r_ready_out     (r_ready_out_ip_sw [i])
  );

  fabric #(
    .DATA_SIZE(4),
    .ADDR_SIZE(1),
    .ADDR(1),
    .NODES_NUM(2),
    .PACKS_TO_GEN(10),
    .MAX_PACK_LEN(10)
  ) IP1 (

  );

  switch #(

  ) sw0 (

  );

  switch #(

  ) sw1 (

  );

	initial
	  begin
			clk_r = 1'b0;
			forever
			  #(period/2) clk_r = ~clk_r;
		end

	initial
		begin
			test_idx = 0;
			rst_r = 1'b1;
      #(10) rst_r = 1'b0;
		end
	
	always @(posedge clk_r)
		begin
			// if (test_idx == 10)
        // $stop;	
			if (test_idx == max_test)
				begin
					$display("Test has been finished");
					$finish;
				end
			test_idx = test_idx + 1;
		end
	
endmodule
