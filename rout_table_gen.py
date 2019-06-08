import argparse
from doc.connection_table_gen import circ2_gen_conn
def add_mod(a, b, n):
    return (a + b) % n

def sub_mod(a, b, n):
    return (a - b) % n

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
                    if sub_mod(sw_dest // h_size, sw_src // h_size, w_size) >= sub_mod(sw_src // h_size, sw_dest // h_size, w_size):
                        temp_rout.append(3)
                    else:
                        temp_rout.append(1)
                elif sub_mod(sw_dest % h_size, sw_src % h_size, h_size) > sub_mod(sw_src % h_size, sw_dest % h_size, h_size):
                    temp_rout.append(2)
                else:
                    temp_rout.append(0)
        rout_table.append(temp_rout)
    return rout_table

def circ2_ROU_gen(nodes_num, s1=1, s2=2):
    rout_table = list() # result
    conns = circ2_gen_conn(nodes_num, s1, s2)
    rout_table.append(list())
    for i in range(1, nodes_num+1):
        if i != 1:
            next_node = ROU_routing(1, i, nodes_num, s1, s2) # getting the nearest router
            # port selecting
            port = int(conns[0][next_node-1])
        else:
            port = 4
        rout_table[0].append(port)
    for i in range(1, nodes_num):
        rout_table.append(list())
        rout_table[-1].extend(rout_table[0][nodes_num-i:])
        rout_table[-1].extend(rout_table[0][:nodes_num-i])
    return rout_table

def ROU_routing(start_node, end_node, nodes_num, s1=1, s2=2):
    if start_node > end_node:
        start_node -= Step_cicles(end_node, start_node, nodes_num, s1, s2)
    else:
        start_node += Step_cicles(end_node, start_node, nodes_num, s1, s2)
    if start_node > end_node:
        return start_node - nodes_num
    elif start_node <= 0:
        return start_node + nodes_num
    return start_node

def Step_cicles(end_node, start_node, nodes_num, s1, s2):
    best_way_R = 0
    step_R = 0
    best_way_L = 0
    step_L = 0
    s = end_node - start_node
    # лучший путь вправо и шаг
    R1 = s / s2 + s % s2
    R2 = s / s2 - s % s2 + s2 + 1
    if s % s2 == 0:
        best_way_R = R1
        step_R = s2
    elif R1 < R2:
        best_way_R = R1
        step_R = s1
    else:
        best_way_R = R2
        step_R = s2
    # 1 цикл
    R5 = (s + nodes_num) / s2 + (s + nodes_num) % s2
    R6 = (s + nodes_num) / s2 - (s + nodes_num) % s2 + s2 + 1
    if R5 < best_way_R:
	    best_way_R = R5
	    step_R = s2
    if R6 < best_way_R:
        best_way_R = R6
        step_R = s2
    # 2 цикл
    R9 = (s + nodes_num + nodes_num) / s2 + (s + nodes_num + nodes_num) % s2
    R10 = (s + nodes_num + nodes_num) / s2 - (s + nodes_num + nodes_num) % s2 + s2 + 1
    if R9 < best_way_R:
        best_way_R = R9
        step_R = s2
    if R10 < best_way_R:
        best_way_R = R10
        step_R = s2
    
	# лучший путь влево и шаг
    s = start_node - end_node + nodes_num
    L1 = s / s2 + s % s2
    L2 = s / s2 - s % s2 + s2 + 1
    if s % s2 == 0:
        best_way_L = L1
        step_L = -s2
    elif L1 < L2:
        best_way_L = L1
        step_L = -s1
    else:
        best_way_L = L2
        step_L = -s2
    # 1 цикл
    R7 = (s + nodes_num) / s2 + (s + nodes_num) % s2
    R8 = (s + nodes_num) / s2 - (s + nodes_num) % s2 + s2 + 1
    if R7 < best_way_L:
        best_way_L = R7
        step_L = -s2
    if R8 < best_way_L:
        best_way_L = R8
        step_L = -s2
    # 2 цикл
    R11 = (s + nodes_num + nodes_num) / s2 + (s + nodes_num + nodes_num) % s2
    R12 = (s + nodes_num + nodes_num) / s2 - (s + nodes_num + nodes_num) % s2 + s2 + 1
    if R11 < best_way_L:
        best_way_L = R11
        step_L = -s2
    if R12 < best_way_L:
        best_way_L = R12
        step_L = -s2
    return step_R if best_way_R < best_way_L else step_L

def arg_parser_create():
    parser = argparse.ArgumentParser(description="Script for generating routing tables for NoC.")
    parser.add_argument('top_types', type=str, nargs='+', choices=['mesh', 'circ2', 'torus'], help="Types of topologies to generate.")
    parser.add_argument('nodes', type=int, default=9, help="Number of nodes in a NoC")
    parser.add_argument('-n', '--name', type=str, default=str(), help="Name of file, there a routing table will be wrote. Default: {top_type}_{params}.srtf.")
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
                filename = f"{args.path}/mesh_{args.nodes}_{args.h_size}.srtf"
            else:
                filename = f"{args.path}/{args.name}.srtf"
            rout_table = mesh_rt_gen(
                            args.nodes,
                            args.h_size
                        )
        elif top_type == "circ2":
            if not args.name:
                filename = f"{args.path}/circ2_{args.nodes}_{args.s1}_{args.s2}.srtf"
            else:
                filename = f"{args.path}/{args.name}.srtf"
            rout_table = circ2_ROU_gen(
                            args.nodes,
                            args.s1,
                            args.s2,
                        )
        elif top_type == "torus":
            if not args.name:
                filename = f"{args.path}/torus_{args.nodes}_{args.h_size}.srtf"
            else:
                filename = f"{args.path}/{args.name}.srtf"
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
