
# create modelsim working library
vlib work

# compile all the Verilog sources
vlog -nologo ../../src/IP/fabric.v ../testbenches/fabric_tb.v

# open the testbench module for simulation
vsim work.fabric_tb

# add all testbench signals to time diagram
# add wave sim:/switch_tb/*
# add wave sim:/switch_tb/test_queue/*

# run the simulation
run -all

# expand the signals time diagram
wave zoom full
