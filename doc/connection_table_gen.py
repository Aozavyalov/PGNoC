import argparse

def add_mod(a, b, n):
    return a + b if a + b < n else a + b - n

def sub_mod(a, b, n):
    return n - b + a if a < b else a - b

def torus_gen_conn(nodes_num, h_size):
    conn_table = [['-' for sw_dst in range(nodes_num)] for sw_src in range(nodes_num)]
    for sw_src in range(nodes_num):
        for sw_dst in range(nodes_num):
            if (sw_dst == sw_src + 1 and sw_src % h_size != h_size - 1) or (sw_src % h_size == h_size - 1 and sw_src-sw_dst-h_size+1 == 0):
                conn_table[sw_src][sw_dst] = '0'
                conn_table[sw_dst][sw_src] = '2'
            elif sw_dst == sw_src + h_size or nodes_num - sw_src + sw_dst == h_size:
                conn_table[sw_src][sw_dst] = '1'
                conn_table[sw_dst][sw_src] = '3'
    return conn_table

def mesh_gen_conn(nodes_num, h_size):
    conn_table = [['-' for sw_dst in range(nodes_num)] for sw_src in range(nodes_num)]
    for sw_src in range(nodes_num):
        for sw_dst in range(sw_src + 1, nodes_num):
            if sw_dst == sw_src + 1 and sw_dst % h_size != 0:
                conn_table[sw_src][sw_dst] = '0'
                conn_table[sw_dst][sw_src] = '2'
            elif sw_dst == h_size + sw_src:
                conn_table[sw_src][sw_dst] = '1'
                conn_table[sw_dst][sw_src] = '3'
    return conn_table

def circ2_gen_conn(nodes_num, s1, s2):
    conn_table = [['-' for sw_dst in range(nodes_num)] for sw_src in range(nodes_num)]
    for sw_src in range(nodes_num):
        # step 0
        conn_table[sw_src][add_mod(sw_src, s1, nodes_num)] = '0'
        conn_table[sw_src][sub_mod(sw_src, s1, nodes_num)] = '3'
        # step 1
        conn_table[sw_src][add_mod(sw_src, s2, nodes_num)] = '1'
        conn_table[sw_src][sub_mod(sw_src, s2, nodes_num)] = '2'
    return conn_table

def arg_parser_create():
    parser = argparse.ArgumentParser(description="Script for generating connection tables for NoC.")
    parser.add_argument('type', type=str, nargs=1, choices=['mesh', 'circ2', 'torus'], help="Types of topologies to generate.")
    parser.add_argument('nodes', type=int, default=9, help="Number of nodes in a NoC")
    parser.add_argument('-h_size', type=int, default=3, help="H_SIZE for mesh.")
    parser.add_argument('-s1', type=int, default=1, help="S1 for cirulant with 2 steps.")
    parser.add_argument('-s2', type=int, default=2, help="S2 for cirulant with 2 steps.")
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args = arg_parser_create()  # getting args
    top_type = args.type[0]
    if top_type == 'mesh':
        conn_table = mesh_gen_conn(nodes_num=args.nodes, h_size=args.h_size)
    elif top_type == 'torus':
        conn_table = torus_gen_conn(nodes_num=args.nodes, h_size=args.h_size)
    elif top_type == 'circ2':
        conn_table = circ2_gen_conn(nodes_num=args.nodes, s1=args.s1, s2=args.s2)
    else:
        print(f"Unknown topology type {top_type}")
        conn_table = None
    if conn_table:
        for src_list in conn_table:
            for port in src_list:
                print(port, end=' ')
            print()
