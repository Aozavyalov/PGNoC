
# create modelsim working library
vlib work

# compile all the Verilog sources
vlog -nologo +define+TESTFILE="../testfiles/queue_tf.hex" ../testbenches/queue_tb.v ../../src/switch/queue.v

# open the testbench module for simulation
vsim work.queue_tb

# add all testbench signals to time diagram
add wave sim:/queue_tb/*
add wave sim:/queue_tb/test_queue/*

# run the simulation
run -all

# expand the signals time diagram
wave zoom full
