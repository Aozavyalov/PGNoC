//  definitions with params of topology. Uncomment if not defined in compiler

// all model params
`define NODES_NUM 9
`define PORTS_NUM 4
`define ADDR_SIZE 5
`define DATA_SIZE 32
`define MEM_LOG2  5

// specific params

// `define MESH_2D  // enabling mesh in topology_module
// `define CIRCULANT_2
`define TORUS

`ifdef MESH_2D
`define RT_PATH "../testfiles/mesh_rt.hex"
`define H_SIZE 2
`endif

`ifdef TORUS
`define RT_PATH "../testfiles/torus_rt.hex"
`define H_SIZE 3
`endif

`ifdef CIRCULANT_2
`define RT_PATH "../testfiles/circ2_rt.hex"
`define S0 1
`define S1 2
`endif

// testing params for fabric module
`define DEBUG        1
`define MAX_PACK_LEN 10
`define PACKS_TO_GEN 5
`define CLK_CNT      1000
`define PERIOD       2
`define GEN_FREQ     25
`define LOGS_PATH    "../logs"