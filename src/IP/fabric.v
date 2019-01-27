`timescale 1ns / 1ns

module fabric #(
  parameter  DATA_SIZE    = 32,   // how many bits use for a data in a flit
  parameter  ADDR_SIZE    = 4,    // how many bits use for an address in a flit
  parameter  ADDR         = 0,    // an address of a node
  parameter  NODES_NUM    = 9,    // a number of nodes in a NoC
  parameter  PACKS_TO_GEN = 10,   // a number of packets to generate and send
  parameter  MAX_PACK_LEN = 10,   // packets a generated with a lenght from 1 to MAX_PACK_LEN
  parameter  DEBUG        = 1'b0, // if debug, messages will be sent to a tcl-console, overwise to a file
  parameter  FREQ         = 25,   // frequence of flits sending. It will be sent 1 flit in FREQ cycles
  parameter  LOGS_PATH    = "..", // a path to a new log file
  parameter  TEST_TIME    = 0,    // then timer will set this value, log file will be closed
  localparam BUS_SIZE = DATA_SIZE + ADDR_SIZE + 1 // a full size of data bus
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

  // var for counting time from reset in cycles
  integer time_int;

  // open log file
  integer log_file; // log file descriptor
  initial
    if (!DEBUG)
      log_file = $fopen({LOGS_PATH, "/logs"});
  
  //////////////////////////////////// generating data ////////////////////////////////////
  // sm states
  localparam PACK_GEN = 2'h0, FLIT_SEND = 2'h1, SEND_ACCEPTING = 2'h2, GEN_FINISH = 2'h3;
  reg [2:0] gen_state; // state reg

  integer generated_packs; // number of generated packets
  integer generated_flits; // number of generated flits in a temp packet
  integer pack_len;        // lenght of temp packet
  integer freq_cntr;       // counter for flit sending

  reg [ADDR_SIZE-1:0] dest_addr;
  reg [DATA_SIZE*MAX_PACK_LEN-1:0] new_packet; // a reg for a full generated packet
  reg fin_flag;                                // reg about finishing

  // generating data to send
  always @(posedge clk)
    if (!a_rst) // use it for dont adding a reset state and a package wont generated
      case (gen_state)
      PACK_GEN: // state there a new packet will be generated
      begin
        pack_len = 1 + $urandom % MAX_PACK_LEN; // a lenght is a random value from 1 to MAX_PACK_LEN
        dest_addr = $urandom % NODES_NUM;       // a destination address is a random value from 0 to NODES_NUM-1
        new_packet = {DATA_SIZE*MAX_PACK_LEN{1'b0}}; // fill reg for packet with zeroes
        // $urandom is only 32 bits, so need "for" generating
        for (generated_flits=0; generated_flits < DATA_SIZE*pack_len/32; generated_flits = generated_flits + 1)
          new_packet[generated_flits*32+:32] = $urandom;
        generated_flits = 0; // just to set 0
        if (dest_addr != ADDR) // if correct address to send (another from ADDR), then send
        begin
          gen_state = FLIT_SEND;
          if (DEBUG)
            $display("%5d|%3h|new package|len: %2h|addr: %3h|%b", time_int, ADDR, pack_len, dest_addr, new_packet);
          else
            $fdisplay(log_file, "%5d|%3h|new package|len: %2h|addr: %3h|%b", time_int, ADDR, pack_len, dest_addr, new_packet);
        end
        else // need just for message while debug
          if (DEBUG)
            $display("%5d|%3h|addr %3h is wrong. Regenerating package", time_int, ADDR, dest_addr);
          else
            $fdisplay(log_file, "%5d|%3h|addr %3h is wrong. Regenerating package", time_int, ADDR, dest_addr);
      end
      FLIT_SEND: // state for flit sending
        if (r_ready_in == 1'b0) // just to be sure that prev sending is ended
          if (freq_cntr == FREQ - 1) // waiting for timer
          begin
            freq_cntr = 0;       // reset timer
            wr_ready_out = 1'b1; // ready to write
            // assemble a flit: data, packet ending bit, dest address
            data_o = {new_packet[generated_flits*DATA_SIZE+:DATA_SIZE], (pack_len - 1 == generated_flits ? 1'b1 : 1'b0), dest_addr};
            generated_flits = generated_flits + 1; // next flit
            // write about new flit
            if (DEBUG)
              $display("%5d|%3h|new flit|%b", time_int, ADDR, data_o);
            else
              $fdisplay(log_file, "%5d|%3h|new flit|%b", time_int, ADDR, data_o);
            gen_state = SEND_ACCEPTING;
          end
          else
            freq_cntr = freq_cntr + 1; // increase freq counter
      SEND_ACCEPTING: // state for accepting of send
        if (r_ready_in == 1'b1) // then flit is readed
        begin
          wr_ready_out = 1'b0;  // dont ready for write
          // message about sending
          if (DEBUG)
            $display("%5d|%3h|flit sended|%b", time_int, ADDR, data_o);
          else
            $fdisplay(log_file, "%5d|%3h|flit sended|%b", time_int, ADDR, data_o);
          if (pack_len > generated_flits)
            gen_state = FLIT_SEND; // if not a last flit, send next
          else
          begin
            generated_packs = generated_packs + 1; // packs counter increase
            // message about full pack sended
            if (DEBUG)
              $display("%5d|%3h|package sended|%2d", time_int, ADDR, generated_packs);
            else
              $fdisplay(log_file, "%5d|%3h|package sended|%2d", time_int, ADDR, generated_packs);
            if (generated_packs == PACKS_TO_GEN) // is a package was last to generate
              gen_state = GEN_FINISH; // goto finish
            else
              gen_state = PACK_GEN;   // else generate a new pack
          end
        end
      GEN_FINISH: // state for stop working. Just write a message about finishing
      begin
        if (!fin_flag) // a flag is needed for only one message
        begin
          if (DEBUG)
            $display("%5d|%3h|finish generating|%5d", time_int, ADDR, generated_packs);
          else
            $fdisplay(log_file, "%5d|%3h|finish generating|%5d", time_int, ADDR, generated_packs);
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
  reg [DATA_SIZE*MAX_PACK_LEN-1:0] recved_packet; // reg with full received packet
  
  always @(posedge clk)
    if (!a_rst)
      case (recv_state)
      GET_FLIT: // state for waiting and getting a flit
        if (wr_ready_in == 1'b1)  // then it has flit to get
        begin
          r_ready_out = 1'b1;     // accept getting
          recv_state  = WAIT_NEXT;   // next state
          recved_packet[recv_flits*DATA_SIZE+:DATA_SIZE] = data_i[ADDR_SIZE+1+:DATA_SIZE+1];
          if (ADDR != data_i[ADDR_SIZE-1:0])  // if wrong address
          begin
            // writing message about wrong flit
            if (DEBUG)
              $display("%5d|%3h|recved wrong flit|real addr: %3h|%b", time_int, ADDR, data_i[ADDR_SIZE-1:0], data_i);
            else
              $fdisplay(log_file, "%5d|%3h|recved wrong flit|real addr: %3h|%b", time_int, ADDR, data_i[ADDR_SIZE-1:0], data_i);
            wrong_flits = wrong_flits + 1;
          end
          else
          begin
            // write message about getting flit
            if (DEBUG)
              $display("%5d|%3h|recved flit|%2d|%b", time_int, ADDR, recv_flits, data_i);
            else
              $fdisplay(log_file, "%5d|%3h|recved flit|%2d|%b", time_int, ADDR, recv_flits, data_i);
            recv_flits = recv_flits + 1;
          end
          if (data_i[ADDR_SIZE] == 1'b1) // if last flit of a package
          begin
            recv_packs = recv_packs + 1;
            if (DEBUG)
              $display("%5d|%3h|recved package|len: %d|packages: %2d|%b", time_int, ADDR, recv_flits, recv_packs, recved_packet);
            else
              $fdisplay(log_file, "%5d|%3h|recved package|len: %d|packages: %2d|%b", time_int, ADDR, recv_flits, recv_packs, recved_packet);
            recved_packet = {DATA_SIZE*MAX_PACK_LEN{1'b0}};
            recv_flits = 0;
          end
        end
      WAIT_NEXT: // state for changing signal about reading
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
    begin // resetting all vars
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
      time_int        = 0;
      fin_flag        = 0;
      recved_packet   = {DATA_SIZE*MAX_PACK_LEN{1'b0}};
      if (DEBUG)
        $display("%5d|%3h|reset", time_int, ADDR);
      else
        $fdisplay(log_file, "%5d|%3h|reset", time_int, ADDR);
    end
    else
    begin // also counting timer
      time_int = time_int + 1;
      if (time_int == TEST_TIME)
        $fclose(log_file);
    end

endmodule // fabric
