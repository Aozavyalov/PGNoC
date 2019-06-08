
# create modelsim working library
vlib work

# compile all the Verilog sources
vlog -nologo ../../src/configs.vh ../../src/connector/*.v ../../src/switch/*.v ../../src/IP/*.v ../testbenches/test_NoC_tb.v

# open the testbench module for simulation
vsim work.test_NoC_tb

# add all testbench signals to time diagram
add wave sim:/test_NoC_tb/*

# run the simulation
run -all

# expand the signals time diagram
wave zoom full
