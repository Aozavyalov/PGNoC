# create modelsim working library
vlib work

# compile all the Verilog sources
vlog -nologo -incr +define+CIRCULANT_2 ../testbenches/circulant_2_tb.v   ../../src/connector/topology_module.v ../../src/connector/circulant_2_gen.v

# open the testbench module for simulation
vsim work.circulant_2_tb

# add all testbench signals to time diagram
add wave sim:/circulant_2_tb/*

# run the simulation
run -all

# expand the signals time diagram
wave zoom full
