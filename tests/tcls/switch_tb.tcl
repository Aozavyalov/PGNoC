
# create modelsim working library
vlib work

# compile all the Verilog sources
vlog -nologo ../testbenches/switch_tb.v ../../src/switch/*.v ../../src/IP/*.v

# open the testbench module for simulation
vsim work.switch_tb

# add all testbench signals to time diagram
add wave sim:/switch_tb/*

# run the simulation
run -all

# expand the signals time diagram
wave zoom full
