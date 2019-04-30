`timescale 1ns / 100ps

`ifndef configs
`define configs
`include "../../src/configs.vh"
`endif

module test_NoC_tb();
  
  localparam halfperiod = `HALFPERIOD;
  localparam max_test  = `TEST_TIME;
  localparam nodes_num = `NODES_NUM;
  localparam ports_num = `PORTS_NUM;
  localparam data_size = `DATA_SIZE;
  localparam addr_size = `ADDR_SIZE;
  localparam flit_delay  = `FLIT_DELAY;
  localparam pack_delay  = `PACK_DELAY;
  localparam mem_log2  = `MEM_LOG2;
  localparam packs_to_gen = `PACKS_TO_GEN;
  localparam max_pack_len = `MAX_PACK_LEN;
  localparam debug = `DEBUG;
  localparam rt_path = `RT_PATH;
  localparam logs_path = `LOGS_PATH;
  localparam flit_size = data_size + addr_size + 1;
  localparam port_size = (flit_size + 2);
  localparam bus_size  = port_size*ports_num;

  `ifdef MESH_2D
  parameter h_size     = `H_SIZE;
  `elsif CIRCULANT_2
  parameter s0         = `S0;
  parameter s1         = `S1;
  `elsif TORUS
  parameter h_size     = `H_SIZE;
  `endif

  reg clk_r;
  reg rst_r;

  // creating a header in log
  integer log_file; // log file descriptor
  initial
    if (!debug)
    begin
      log_file = $fopen({logs_path, "/logs"});
      `ifdef MESH_2D
      $fdisplay(log_file, "Mesh, nodes %d, h_size %d, ports %d, flit_size %d, addr_size %d", nodes_num, h_size, ports_num, flit_size, addr_size);
      `elsif CIRCULANT_2
      $fdisplay(log_file, "Circulant2, nodes %d, s0 %d, s1 %d, ports %d, flit_size %d, addr_size %d", nodes_num, s0, s1, ports_num, flit_size, addr_size);
      `elsif TORUS
      $fdisplay(log_file, "Torus, nodes %d, h_size %d, ports %d, flit_size %d, addr_size %d", nodes_num, h_size, ports_num, flit_size, addr_size);
      `endif
    end

  // connections and modules

  // connector buses
  wire [nodes_num*bus_size-1:0] conn_in;
  wire [nodes_num*bus_size-1:0] conn_out;
  reg [nodes_num*bus_size-1:0] conn_out_reg;

  // IP + switch connection
  genvar node_idx, port_idx;
  generate
  for (node_idx = 0; node_idx < nodes_num; node_idx = node_idx + 1)
  begin : IP_to_switch
    // ip to switcher
    wire [flit_size-1:0] ip_data_o;
    wire [flit_size-1:0] ip_data_i;
    wire                 ip_r_ready_out  ;
    wire                 ip_wr_ready_out ;
    wire                 ip_wr_ready_in  ;
    wire                 ip_r_ready_in ;
    // switcher to adapter
    wire [flit_size*ports_num-1:0] sw_data_i;
    wire [flit_size*ports_num-1:0] sw_data_o;
    wire [ports_num-1:0]           sw_r_ready_out ;
    wire [ports_num-1:0]           sw_wr_ready_out;
    wire [ports_num-1:0]           sw_wr_ready_in ;
    wire [ports_num-1:0]           sw_r_ready_in;
    wire [31:0]                    recv_packs;
    // sum of packets for stopping testbench
    wire [31:0] recved_packet_sum;
    // IP node_idx
    fabric #(
      .DATA_SIZE   (data_size),
      .ADDR_SIZE   (addr_size),
      .ADDR        (node_idx),
      .NODES_NUM   (nodes_num),
      .PACKS_TO_GEN(packs_to_gen),
      .MAX_PACK_LEN(max_pack_len),
      .DEBUG       (debug),
      .FLIT_DELAY  (flit_delay),
      .PACK_DELAY  (pack_delay),
      .LOGS_PATH   (logs_path),
      .TEST_TIME   (max_test)
    ) IP (
      .clk         (clk_r),
      .a_rst       (rst_r),
      .data_i      (ip_data_i),
      .data_o      (ip_data_o),
      .r_ready_in  (ip_r_ready_in),
      .wr_ready_in (ip_wr_ready_in),
      .wr_ready_out(ip_wr_ready_out),
      .r_ready_out (ip_r_ready_out),
      .recv_packs  (recv_packs)
    );
    // switch node_idx
    switch #(
      .DATA_SIZE(data_size),
      .ADDR_SIZE(addr_size),
      .PORTS_NUM(ports_num),
      .NODES_NUM(nodes_num),
      .ADDR     (node_idx),
      .MEM_LOG2 (mem_log2),
      .RT_PATH  (rt_path)
    ) SW (
      .clk         (clk_r),
      .a_rst       (rst_r),
      .wr_ready_in ({ip_wr_ready_out , sw_wr_ready_in  }),
      .r_ready_in  ({ip_r_ready_out  , sw_r_ready_in }),
      .data_i      ({ip_data_o, sw_data_i}),
      .r_ready_out ({ip_r_ready_in , sw_r_ready_out  }),
      .wr_ready_out({ip_wr_ready_in  , sw_wr_ready_out }),
      .data_o      ({ip_data_i, sw_data_o})
    );
    // connect topology module and switches
    for (port_idx = 0; port_idx < ports_num; port_idx = port_idx + 1)
    begin : port_connections
      // port is data + read signal + write signal
      assign conn_in[node_idx*bus_size+port_idx*port_size+:port_size] = {sw_data_o[port_idx*flit_size+:flit_size], sw_r_ready_out[port_idx], sw_wr_ready_out[port_idx]};
      assign {sw_data_i[port_idx*flit_size+:flit_size], sw_r_ready_in[port_idx], sw_wr_ready_in[port_idx]} = conn_out[node_idx*bus_size+port_idx*port_size+:port_size];
    end
    // sum of all received packages
    if (node_idx == 0)
      assign IP_to_switch[0].recved_packet_sum = IP_to_switch[0].recv_packs;
    else
      assign IP_to_switch[node_idx].recved_packet_sum = IP_to_switch[node_idx-1].recved_packet_sum + IP_to_switch[node_idx].recv_packs;
  end // IP_to_switch
  endgenerate

  topology_module #(
      .PORT_SIZE(port_size),
      .NODES_NUM(nodes_num),
      .PORTS_NUM(ports_num),
  `ifdef MESH_2D
      .H_SIZE(h_size)
  `elsif CIRCULANT_2
      .S0(s0),
      .S1(s1)
  `elsif TORUS
      .H_SIZE(h_size)
  `endif 
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
  integer repeat_num;
  initial
  begin
    repeat_num = 0;
    test_idx = 0;
    rst_r = 1'b1;
    #(halfperiod) rst_r = 1'b0;
  end
  
  always @(posedge clk_r)
  begin
    if (conn_out_reg !== conn_out)
    begin
      conn_out_reg = conn_out;
      repeat_num = 0;
    end
    else
      repeat_num = repeat_num + 1;
    if (repeat_num == 10_000)
    begin
      if (debug)
        $display("Test has been finished untimely, %d packets received", IP_to_switch[nodes_num-1].recved_packet_sum);
      else
      begin
        $fdisplay(log_file, "Test has been finished untimely, %d packets received", IP_to_switch[nodes_num-1].recved_packet_sum);
        $fclose(log_file);
      end
      $finish;
    end
    if (test_idx == max_test || IP_to_switch[nodes_num-1].recved_packet_sum == packs_to_gen*nodes_num)
    begin
      if (debug)
        $display("Test has been completed, %d packets received", IP_to_switch[nodes_num-1].recved_packet_sum);
      else
      begin
        $fdisplay(log_file, "Test has been completed, %d packets received", IP_to_switch[nodes_num-1].recved_packet_sum);
        $fclose(log_file);
      end
      $finish;
    end
    test_idx = test_idx + 1;
  end
  
endmodule // fake_NoC_tb