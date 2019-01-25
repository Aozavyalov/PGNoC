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
  // connections with router
  input                     wr_ready_in,
  input                     r_ready_in,
  input      [BUS_SIZE-1:0] data_i,
  output reg                r_ready_out,
  output reg                wr_ready_out,
  output reg [BUS_SIZE-1:0] data_o,
  // additional info
  output reg [31:0]         recv_packs   // received packs num
);

  integer time_reg;

  // open log file
  integer log_file;
  initial
    if (!DEBUG)
      log_file = $fopen({`LOGS_PATH, "/logs"});
  
  //////////////////////////////////// generating data ////////////////////////////////////
  // sm states
  localparam PACK_GEN = 2'h0, FLIT_GEN = 2'h1, FLIT_SEND = 2'h2, GEN_FINISH = 2'h3;
  reg [2:0] gen_state; // state reg

  integer generated_packs;
  integer generated_flits;
  integer pack_len;
  integer freq_cntr;

  reg [ADDR_SIZE-1:0] dest_addr;
  reg [DATA_SIZE*MAX_PACK_LEN-1:0] new_packet; // a reg for a full generated packet
  reg fin_flag;                                // reg about finishing

  // generating data to send
  always @(posedge clk)
    if (!a_rst)
      case (gen_state)
      PACK_GEN:
      begin
        pack_len = 1 + $urandom % MAX_PACK_LEN;
        dest_addr = $urandom % NODES_NUM;
        for (generated_flits=0; generated_flits < DATA_SIZE*pack_len/32; generated_flits = generated_flits + 1)
          new_packet[generated_flits*32+:32] = $urandom;
        generated_flits = 0;
        if (dest_addr != ADDR)
        begin
          gen_state = FLIT_GEN;
          if (DEBUG)
            $display("%5d|%3h|new package|len: %2h|addr: %3h", time_reg, ADDR, pack_len, dest_addr);
          else
            $fdisplay(log_file, "%5d|%3h|new package|len: %2h|addr: %3h", time_reg, ADDR, pack_len, dest_addr);
        end
        else
          if (DEBUG)
            $display("%5d|%3h|addr %3h is wrong. Regenerating package", time_reg, ADDR, dest_addr);
          else
            $fdisplay(log_file, "%5d|%3h|addr %3h is wrong. Regenerating package", time_reg, ADDR, dest_addr);
      end
      FLIT_GEN:
        if (r_ready_in == 1'b0)
          if (freq_cntr == FREQ - 1)
          begin
            freq_cntr = 0;
            wr_ready_out = 1'b1;
            data_o = {new_packet[generated_flits*DATA_SIZE+:DATA_SIZE], (pack_len - 1 == generated_flits ? 1'b1 : 1'b0), dest_addr};
            generated_flits = generated_flits + 1;
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
          if (pack_len == generated_flits)
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
            gen_state = FLIT_GEN;
        end
      GEN_FINISH:
      begin
        if (!fin_flag)
        begin
          if (DEBUG)
            $display("%5d|%3h|finish generating|%5d", time_reg, ADDR, generated_packs);
          else
            $fdisplay(log_file, "%5d|%3h|finish generating|%5d", time_reg, ADDR, generated_packs);
          fin_flag = 1'b1;
        end
      end
      default: gen_state = PACK_GEN;
  endcase
  //////////////////////////////////// end generating ////////////////////////////////////

  //////////////////////////////////// receiving ////////////////////////////////////
  localparam GET_FLIT = 1'h0, WAIT_NEXT = 1'h1; // sm states
  reg [2:0] recv_state;                      // state reg
  integer recv_flits;                        // received flits num
  integer wrong_flits;                       // wrong flits num
  
  always @(posedge clk)
    if (!a_rst)
      case (recv_state)
      GET_FLIT:
        if (wr_ready_in == 1'b1)  // then it has flit to get
        begin
          r_ready_out = 1'b1;     // accept getting
          recv_state  = WAIT_NEXT;   // next state
          if (ADDR != data_i[ADDR_SIZE-1:0])  // if wrong address
          begin
            // writing message about wrong flit
            if (DEBUG)
              $display("%5d|%3h|recved wrong flit|real addr: %3h|%b", time_reg, ADDR, data_i[ADDR_SIZE-1:0], data_i);
            else
              $fdisplay(log_file, "%5d|%3h|recved wrong flit|real addr: %3h|%b", time_reg, ADDR, data_i[ADDR_SIZE-1:0], data_i);
            wrong_flits = wrong_flits + 1;
          end
          else
          begin
            // write message about getting flit
            if (DEBUG)
              $display("%5d|%3h|recved flit|%2d|%b", time_reg, ADDR, recv_flits, data_i);
            else
              $fdisplay(log_file, "%5d|%3h|recved flit|%2d|%b", time_reg, ADDR, recv_flits, data_i);
            recv_flits = recv_flits + 1;
          end
          if (data_i[ADDR_SIZE] == 1'b1)    // if last flit of a package
          begin
            if (DEBUG)
              $display("%5d|%3h|recved package|packages: %2d", time_reg, ADDR, recv_packs);
            else
              $fdisplay(log_file, "%5d|%3h|recved package|packages: %2d", time_reg, ADDR, recv_packs);
            recv_packs = recv_packs + 1;
            recv_flits = 0;
          end
        end
      WAIT_NEXT:
      begin
        r_ready_out = 1'b0;
        recv_state = GET_FLIT;
      end
      default: recv_state = GET_FLIT;
      endcase

  //////////////////////////////////// end receiving ////////////////////////////////////

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
      recv_state      = GET_FLIT;
      recv_packs      = 0;
      recv_flits      = 0;
      wrong_flits     = 0;
      time_reg        = 0;
      fin_flag        = 0;
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
