transcript off
# create modelsim working library
vlib work

# compile all the Verilog sources
vlog -nologo ../testbenches/transceiver_tb.v ../../src/switch/transceiver.v ../../src/switch/routing_mod.v

# open the testbench module for simulation
vsim work.transceiver_tb

# add all testbench signals to time diagram
add wave sim:/transceiver_tb/*
add wave sim:/transceiver_tb/test_trans/*

# run the simulation
run -all

# expand the signals time diagram
wave zoom full
