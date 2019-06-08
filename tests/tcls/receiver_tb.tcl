transcript off
# create modelsim working library
vlib work

# compile all the Verilog sources
vlog -nologo ../testbenches/receiver_tb.v ../../src/switch/receiver.v

# open the testbench module for simulation
vsim work.receiver_tb

# add all testbench signals to time diagram
add wave sim:/receiver_tb/*
add wave sim:/receiver_tb/test_recv/*

# run the simulation
run -all

# expand the signals time diagram
wave zoom full
