`timescale 1ns / 1ns
`include "../../src/configs.vh"

module fabric #(
  parameter  DATA_SIZE    = 32,
  parameter  ADDR_SIZE    = 4,
  parameter  ADDR         = 0,
  parameter  NODES_NUM    = 9,
  parameter  PACKS_TO_GEN = 10,
  parameter  MAX_PACK_LEN = 10,
  parameter  DEBUG        = 1'b0,
  parameter  FREQ         = 25,
  localparam BUS_SIZE = DATA_SIZE + ADDR_SIZE + 1
) (
  input                     clk,
  input                     a_rst,
  input                     wr_ready_in,
  input                     r_ready_in,
  input      [BUS_SIZE-1:0] data_i,
  output reg                r_ready_out,
  output reg                wr_ready_out,
  output reg [BUS_SIZE-1:0] data_o
);

  integer time_reg;
  // generating data
  localparam RESET = 3'h0, PACK_GEN = 3'h1, FLIT_GEN = 3'h2, FLIT_SEND = 3'h3, GEN_FINISH = 3'h4;

  integer generated_packs;
  integer pack_len;
  integer freq_cntr;

  reg [2:0] gen_state;
  reg [ADDR_SIZE-1:0] dest_addr;
  reg [DATA_SIZE-1:0] gen_data;

  // open log file
  integer log_file;
  initial
    if (!DEBUG)
      log_file = $fopen({`LOGS_PATH, "/logs"});

  // generating data to send
  always @(posedge clk, posedge a_rst)
    case (gen_state)
    PACK_GEN:
    begin
      pack_len = $urandom % MAX_PACK_LEN;
      dest_addr = $urandom % NODES_NUM;
      if (dest_addr != ADDR)
      begin
        gen_state = FLIT_GEN;
        if (DEBUG)
          $display("%5d|%3h|new package|len: %2h|addr: %3h", time_reg, ADDR, pack_len + 1, dest_addr);
        else
          $fdisplay(log_file, "%5d|%3h|new package|len: %2h|addr: %3h", time_reg, ADDR, pack_len + 1, dest_addr);
      end
    end
    FLIT_GEN:
      if (r_ready_in == 1'b0)
        if (freq_cntr == FREQ - 1)
        begin
          freq_cntr = 0;
          wr_ready_out = 1'b1;
          gen_data = $urandom;
          data_o = {gen_data, (pack_len == 0 ? 1'b1 : 1'b0), dest_addr};  
          if (DEBUG)     
            $display("%5d|%3h|new flit|%b", time_reg, ADDR, data_o);
          else
            $fdisplay(log_file, "%5d|%3h|new flit|%b", time_reg, ADDR, data_o);
          gen_state = FLIT_SEND;
        end
        else
          freq_cntr = freq_cntr + 1;
    FLIT_SEND:
      if (r_ready_in == 1'b1)
      begin
        wr_ready_out = 1'b0;
        if (DEBUG)
          $display("%5d|%3h|flit sended|%b", time_reg, ADDR, data_o);
        else
          $fdisplay(log_file, "%5d|%3h|flit sended|%b", time_reg, ADDR, data_o);
        if (pack_len == 0)
        begin
          generated_packs = generated_packs + 1;
          if (DEBUG)
            $display("%5d|%3h|package sended|%2d", time_reg, ADDR, generated_packs);
          else
            $fdisplay(log_file, "%5d|%3h|package sended|%2d", time_reg, ADDR, generated_packs);
          if (generated_packs == PACKS_TO_GEN)
            gen_state = GEN_FINISH;
          else
            gen_state = PACK_GEN;
        end
        else
        begin
          gen_state = FLIT_GEN;
          pack_len  = pack_len - 1;
        end
      end
    GEN_FINISH:
    begin
      if (DEBUG)
        $display("%5d|%3h|finish generating|%5d", time_reg, ADDR, generated_packs);
      else
        $fdisplay(log_file, "%5d|%3h|finish generating|%5d", time_reg, ADDR, generated_packs);
    end
    default: gen_state = RESET;
  endcase

  localparam WAIT = 1'h0, GET = 1'h1;
  reg [2:0] recv_state;
  integer recv_flits;
  integer wrong_packs;
  integer recv_packs;
  
  // receiving data
  always @(posedge clk, posedge a_rst)
    case (recv_state)
    WAIT:
      if (wr_ready_in == 1'b1)
      begin
        r_ready_out = 1'b1;
        recv_state  = GET;
        recv_packs  = 0;
        if (DEBUG)
          $display("%5d|%3h|wait for reading", time_reg, ADDR);
        else
          $fdisplay(log_file, "%5d|%3h|wait for reading", time_reg, ADDR);
      end
    GET:
      if (wr_ready_in == 1'b0)
      begin
        r_ready_out = 1'b0;
        if (ADDR != data_i[ADDR_SIZE-1:0])  // if wrong address
        begin
          if (DEBUG)
            $display("%5d|%3h|recved wrong flit|real addr: %3h|%b", time_reg, ADDR, data_i[ADDR_SIZE-1:0], data_i);
          else
            $fdisplay(log_file, "%5d|%3h|recved wrong flit|real addr: %3h|%b", time_reg, ADDR, data_i[ADDR_SIZE-1:0], data_i);
          wrong_packs = wrong_packs + 1;
        end
        else
          if (DEBUG)
            $display("%5d|%3h|recved flit|%2d|%b", time_reg, ADDR, recv_flits, data_i);
          else
            $fdisplay(log_file, "%5d|%3h|recved flit|%2d|%b", time_reg, ADDR, recv_flits, data_i);
        if (data_i[ADDR_SIZE] == 1'b1)    // if last flit of a package
        begin
          recv_packs = recv_packs + 1;
          recv_flits = 0;
          if (DEBUG)
            $display("%5d|%3h|recved package|packages: %2d", time_reg, ADDR, recv_packs);
          else
            $fdisplay(log_file, "%5d|%3h|recved package|packages: %2d", time_reg, ADDR, recv_packs);
        end
        else
          recv_flits = recv_flits + 1;
        recv_state = WAIT;
      end
    endcase

  // resetting and time counting
  always @(posedge clk, posedge a_rst)
    if (a_rst)
    begin
      wr_ready_out    = 1'b0;
      gen_state       = PACK_GEN;
      pack_len        = 0;
      generated_packs = 0;
      freq_cntr       = 0;
      r_ready_out     = 1'b0;
      recv_state      = WAIT;
      recv_flits      = 0;
      wrong_packs     = 0;
      time_reg        = 0;
      if (DEBUG)
        $display("%5d|%3h|reset", time_reg, ADDR);
      else
        $fdisplay(log_file, "%5d|%3h|reset", time_reg, ADDR);
    end
    else
    begin
      time_reg = time_reg + 1;
      if (time_reg == `TEST_TIME)
        $fclose(log_file);
    end

endmodule // fabric
