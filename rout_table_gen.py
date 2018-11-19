import argparse

def add_mod(a, b, n):
    return a + b if a + b < n else a + b - n

def sub_mod(a, b, n):
    return n - b + a if a < b else a - b

def mesh_rt_gen(nodes_num, h_size):
    rout_table = list()
    w_size = nodes_num // h_size
    for sw_src in range(nodes_num):
        temp_rout = list()
        for sw_dest in range(nodes_num):
            if (sw_src == sw_dest):   # port 4
                temp_rout.append(4)
            else:
                if (sw_dest % h_size < sw_src % h_size):
                    temp_rout.append(2)
                elif (sw_dest % h_size > sw_src % h_size):
                    temp_rout.append(0)
                else:
                    if sw_dest > sw_src:
                        temp_rout.append(1)
                    else:
                        temp_rout.append(3)
        rout_table.append(temp_rout)
    return rout_table

def circ2_rt_gen(nodes_num, s1, s2):
    rout_table = list()
    routs = {0: 4}
    routs[add_mod(0, s1, nodes_num)] = 0
    routs[add_mod(0, s2, nodes_num)] = 1
    routs[sub_mod(0, s2, nodes_num)] = 2
    routs[sub_mod(0, s1, nodes_num)] = 3
    # check for not included nodes
    for i in range(nodes_num):
        if i not in routs.keys():
            conns = list()
            if sub_mod(i, s1, nodes_num) in routs:
                conns.append(routs[sub_mod(i, s1, nodes_num)])
            if sub_mod(i, s2, nodes_num) in routs:
                conns.append(routs[sub_mod(i, s2, nodes_num)])
            if add_mod(i, s1, nodes_num) in routs:
                conns.append(routs[add_mod(i, s1, nodes_num)])
            if add_mod(i, s2, nodes_num) in routs:
                conns.append(routs[add_mod(i, s2, nodes_num)])
            if i <= nodes_num // 2:
                routs[i] = min(conns)
            else:
                routs[i] = max(conns)
    sample = list()
    for key in sorted(routs):
        sample.append(routs[key])
    # routing table forming
    for i in range(nodes_num):
        buf = sample[-i:]
        buf.extend(sample[:-i])
        rout_table.append(buf)
    return rout_table

def torus_rt_gen(nodes_num, h_size):
    rout_table = list()
    w_size = nodes_num // h_size
    for sw_src in range(nodes_num):
        temp_rout = list()
        for sw_dest in range(nodes_num):
            if (sw_src == sw_dest):   # port 4
                temp_rout.append(4)
            else:
                if sw_src % h_size == sw_dest % h_size:  # if nodes on one line
                    if sub_mod(sw_dest // h_size, sw_src // h_size, h_size) > sub_mod(sw_src // h_size, sw_dest // h_size, h_size):
                        temp_rout.append(3)
                    else:
                        temp_rout.append(1)
                elif sub_mod(sw_dest % h_size, sw_src % h_size, h_size) > sub_mod(sw_src % h_size, sw_dest % h_size, h_size):
                    temp_rout.append(2)
                else:
                    temp_rout.append(0)
        rout_table.append(temp_rout)
    return rout_table

def arg_parser_create():
    parser = argparse.ArgumentParser(description="Script for generating routing tables for NoC.")
    parser.add_argument('top_types', type=str, nargs='+', choices=['mesh', 'circ2', 'torus'], help="Types of topologies to generate.")
    parser.add_argument('nodes', type=int, default=9, help="Number of nodes in a NoC")
    parser.add_argument('-n', '--name', type=str, default=str(), help="Name of file, there a routing table will be wrote. Default: {top_type}_{params}.hex.")
    parser.add_argument('-i', '--invert', type=bool, default=True, help="Parameter to invert or not a routing table. Default True.")
    parser.add_argument('-t', '--transpose', type=bool, default=False, help="Parameter to transpose a routing table or not. Default False.")
    parser.add_argument('-h_size', type=int, default=3, help="H_SIZE for mesh.")
    parser.add_argument('-s1', type=int, default=1, help="S1 for cirulant with 2 steps.")
    parser.add_argument('-s2', type=int, default=2, help="S2 for cirulant with 2 steps.")
    parser.add_argument('-p', '--path', type=str, default='.', help="Path to file where to save.")
    args = parser.parse_args()
    return args

def rout_table_to_str(rout_table, transpose=False, invert=False):
    res_str = str()
    if transpose:
        rout_table = list(map(list, zip(*rout_table)))
    for line in rout_table:
        if invert:
            res_str += ''.join(str(num) for num in line[::-1]) + '\n'
        else:
            res_str += ''.join(str(num) for num in line) + '\n'
    return res_str

if __name__ == "__main__":
    args = arg_parser_create()  # getting args
    top_types = args.top_types
    # top_types = ['circ2']
    for top_type in top_types:
        if top_type == "mesh":
            if not args.name:
                filename = f"{args.path}/mesh_{args.nodes}_{args.h_size}.hex"
            else:
                filename = f"{args.path}/{args.name}.hex"
            rout_table = mesh_rt_gen(
                            args.nodes,
                            args.h_size
                        )
        elif top_type == "circ2":
            if not args.name:
                filename = f"{args.path}/circ2_{args.nodes}_{args.s1}_{args.s2}.hex"
            else:
                filename = f"{args.path}/{args.name}.hex"
            rout_table = circ2_rt_gen(
                            args.nodes,
                            args.s1,
                            args.s2,
                        )
        elif top_type == "torus":
            if not args.name:
                filename = f"{args.path}/torus_{args.nodes}_{args.h_size}.hex"
            else:
                filename = f"{args.path}/{args.name}.hex"
            rout_table = torus_rt_gen(
                            args.nodes,
                            args.h_size
                        )
        else:
            print('Unknown topology type!')
            continue
        # print(rout_table_to_str(rout_table, args.transpose, args.invert))
        with open(filename, 'w') as f:
            f.write(rout_table_to_str(rout_table, args.transpose, args.invert))
        print(f"Routing table of type {top_type} generated to {filename}")
