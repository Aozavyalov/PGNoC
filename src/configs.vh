//  definitions with params of topology. Uncomment if not defined in compiler

// all model params
`define NODES_NUM 25
`define PORTS_NUM 4
`define ADDR_SIZE 6
`define DATA_SIZE 32
`define MEM_LOG2  5

// specific params

`define MESH_2D  // enabling mesh in topology_module
// `define CIRCULANT_2
// `define TORUS

`ifdef MESH_2D
`define RT_PATH "../mesh_rt.srtf"
`define H_SIZE 5
`endif

`ifdef TORUS
`define RT_PATH "../torus_rt.srtf"
`define H_SIZE 5
`endif

`ifdef CIRCULANT_2
`define RT_PATH "../circ2_rt.srtf"
`define S0 1
`define S1 2
`endif

// testing params for fabric module
`define DEBUG        1
`define MAX_PACK_LEN 10
`define PACKS_TO_GEN 11000
`define TEST_TIME    10_000_000
`define HALFPERIOD   1
`define FLIT_DELAY   1
`define PACK_DELAY   300
`define LOGS_PATH    "../logs"
