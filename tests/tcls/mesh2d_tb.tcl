# create modelsim working library
vlib work

# compile all the Verilog sources
vlog -nologo -incr +define+MESH_2D ../testbenches/mesh2d_tb.v   ../../src/connector/topology_module.v ../../src/connector/mesh_2d_gen.v

# open the testbench module for simulation
vsim work.mesh2d_tb

# add all testbench signals to time diagram
add wave sim:/mesh2d_tb/*

# run the simulation
run -all

# expand the signals time diagram
wave zoom full
