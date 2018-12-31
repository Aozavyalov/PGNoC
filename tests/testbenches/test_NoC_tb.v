`timescale 1ns / 100ps
`include "../../src/configs.vh"

module test_NoC_tb();
  
  localparam halfperiod = `HALFPERIOD;
  localparam max_test  = `TEST_TIME;
  localparam nodes_num = `NODES_NUM;
  localparam ports_num = `PORTS_NUM;
  localparam data_size = `DATA_SIZE;
  localparam addr_size = `ADDR_SIZE;
  localparam gen_freq  = `GEN_FREQ;
  localparam mem_log2  = `MEM_LOG2;
  localparam packs_to_gen = `PACKS_TO_GEN;
  localparam max_pack_len = `MAX_PACK_LEN;
  localparam debug = `DEBUG;
  localparam flit_size = data_size + addr_size + 1;
  localparam port_size = (flit_size + 2);
  localparam bus_size  = port_size*ports_num;

  `ifdef MESH_2D
  parameter h_size     = `H_SIZE;
  `else
  `ifdef CIRCULANT_2
  parameter s0         = `S0;
  parameter s1         = `S1;
  `else
  `ifdef TORUS
  parameter h_size     = `H_SIZE;
  `endif // TORUS
  `endif // CIRCULANT_2
  `endif // MESH_2D

  reg clk_r;
  reg rst_r;

  // connections and modules

  // connector buses
  wire [nodes_num*bus_size-1:0] conn_in;
  wire [nodes_num*bus_size-1:0] conn_out;

  // IP + switch connection
  genvar i;
  generate
    for (i = 0; i < nodes_num; i = i + 1)
      begin : IP_to_switch
        // ip to switcher
        wire [flit_size-1:0] ip_data_o;
        wire [flit_size-1:0] ip_data_i;
        wire                 ip_in_w  ;
        wire                 ip_out_r ;
        wire                 ip_in_r  ;
        wire                 ip_out_w ;
        // switcher to adapter
        wire [flit_size*ports_num-1:0] sw_data_i;
        wire [flit_size*ports_num-1:0] sw_data_o;
        wire [ports_num-1:0]           sw_in_w ;
        wire [ports_num-1:0]           sw_out_r;
        wire [ports_num-1:0]           sw_in_r ;
        wire [ports_num-1:0]           sw_out_w;
        // IP i
        fabric #(
          .DATA_SIZE(data_size),
          .ADDR_SIZE(addr_size),
          .ADDR(i),
          .NODES_NUM(nodes_num),
          .PACKS_TO_GEN(packs_to_gen),
          .MAX_PACK_LEN(max_pack_len),
          .DEBUG(debug),
          .FREQ(gen_freq)
        ) IP (
          .clk      (clk_r),
          .a_rst    (rst_r),
          .data_i   (ip_data_i),
          .data_o   (ip_data_o),
          .out_w    (ip_out_w ),
          .in_r     (ip_in_r  ),
          .out_r    (ip_out_r ),
          .in_w     (ip_in_w  )
        );
        // switch i
        switch #(
          .DATA_SIZE(data_size),
          .ADDR_SIZE(addr_size),
          .PORTS_NUM(ports_num),
          .NODES_NUM(nodes_num),
          .ADDR     (i),
          .MEM_LOG2 (mem_log2)
        ) SW (
          .clk   (clk_r),
          .a_rst (rst_r),
          .in_r  ({ip_out_r , sw_in_r  }),
          .out_w ({ip_in_w  , sw_out_w }),
          .data_i({ip_data_o, sw_data_i}),
          .in_w  ({ip_out_w , sw_in_w  }),
          .out_r ({ip_in_r  , sw_out_r }),
          .data_o({ip_data_i, sw_data_o})
        );
        // switch to connector adapter
        sw_to_connector #(
          .FLIT_SIZE(flit_size),
          .PORTS_NUM(ports_num)
        ) out_adapter (
          .in_w   (sw_in_w                      ),
          .out_r  (sw_out_r                     ),
          .sw_data(sw_data_o                    ),
          .bus    (conn_in[i*bus_size+:bus_size])
        );
        // connector to switch adapter
        connector_to_sw #(
          .FLIT_SIZE(flit_size),
          .PORTS_NUM(ports_num)
        ) in_adapter (
          .bus    (conn_out[i*bus_size+:bus_size]),
          .in_r   (sw_in_r                       ),
          .out_w  (sw_out_w                      ),
          .sw_data(sw_data_i                     )
        );
      end
  endgenerate

  topology_module #(
      .PORT_SIZE(port_size),
      .NODES_NUM(nodes_num),
      .PORTS_NUM(ports_num),
  `ifdef MESH_2D
      .H_SIZE(h_size)
  `else
  `ifdef CIRCULANT_2
      .S0(s0),
      .S1(s1)
  `else
  `ifdef TORUS
      .H_SIZE(h_size)
  `endif // TORUS
  `endif // CIRCULANT_2
  `endif // MESH_2D
    ) top_mod (
      .data_i (conn_in),
      .data_o (conn_out)
    );

  // end connections

  initial
    begin
      clk_r = 1'b0;
      forever
        #(halfperiod) clk_r = ~clk_r;
    end

  integer test_idx;
  integer conn_change_timer;
  reg [nodes_num*bus_size-1:0] prev_conn_out;
  initial
    begin
      conn_change_timer = 0;
      test_idx = 0;
      rst_r = 1'b1;
      #(2*halfperiod) rst_r = 1'b0;
    end
  
  always @(posedge clk_r)
    begin
      if (prev_conn_out !== conn_out) begin
        prev_conn_out = conn_out;
        conn_change_timer = 0;
      end else
        conn_change_timer = conn_change_timer + 1;
      if (test_idx == max_test || conn_change_timer == gen_freq*10)
        begin
          $display("Test has been finished");
          $finish;
        end
      test_idx = test_idx + 1;
    end
  
endmodule // fake_NoC_tb