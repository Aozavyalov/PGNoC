import argparse

def arg_parser_create():
    parser = argparse.ArgumentParser(description="Script for generating of tests for different topologies")
    parser.add_argument('top_types', type=str, nargs='+')
    parser.add_argument('-p', '--path', type=str, default='.')
    args = parser.parse_args()
    return args

def str_l_shift(string, num):
    return string[num:] + string[:num]

def add_mod(a, b, size):
    return a + b if a + b < size else a + b - size

def sub_mod(a, b, size):
    return size - b + a if a - b < 0 else a - b

def circ2_gen(data_i, routs_num, s0, s1, bus_size, add_z_n=0):
    data_i = data_i[::-1]
    data_o_list = ['z' for i in range(routs_num*4*bus_size)]
    for i in range(routs_num):
        # s0
        # print(add_mod(i, s0, routs_num), i)
        # print(data_i[i*4*bus_size+0*bus_size:i*4*bus_size+0*bus_size+bus_size])
        rigth_rout_0 = add_mod(i, s0, routs_num)
        left_rout_0 = sub_mod(i, s0, routs_num)
        rigth_rout_1 = add_mod(i, s1, routs_num)
        left_rout_1 = sub_mod(i, s1, routs_num)
        for k in range(bus_size):
            data_o_list[rigth_rout_0*4*bus_size+3*bus_size+k] = data_i[i*4*bus_size+0*bus_size+k]

        for k in range(bus_size):
            data_o_list[left_rout_0*4*bus_size+0*bus_size+k] = data_i[i*4*bus_size+3*bus_size+k]

        # s1
        for k in range(bus_size):
            data_o_list[rigth_rout_1*4*bus_size+1*bus_size+k] = data_i[i*4*bus_size+2*bus_size+k]

        # for k in range(bus_size):
        #     data_o_list[i*4*bus_size+2*bus_size+k] = data_i[rigth_rout_1*4*bus_size+3*bus_size+k]
        # out_w_o_list[i*4+2] = in_w_i[rigth_rout_1*4+3]
        # in_r_o_list[i*4+2] = out_r_i[rigth_rout_1*4+3]

        for k in range(bus_size):
            data_o_list[left_rout_1*4*bus_size+2*bus_size+k] = data_i[i*4*bus_size+1*bus_size+k]

        # for k in range(bus_size):
        #     data_o_list[i*4*bus_size+3*bus_size+k] = data_i[left_rout_1*4*bus_size+2*bus_size+k]
        # out_w_o_list[i*4+3] = in_w_i[left_rout_1*4+2]
        # in_r_o_list[i*4+3] = out_r_i[left_rout_1*4+2]
        # print(i, out_w_o_list)
    return 'z'*add_z_n*4*bus_size + ''.join(data_o_list)[::-1], 'z'*add_z_n*4 + ''.join(out_w_o_list)[::-1], 'z'*add_z_n*4 + ''.join(in_r_o_list)[::-1]

def mesh_2d_gen(data_i, routs_num, h_size, bus_size, add_z_n=0):
    data_i = data_i[::-1]
    data_o_list = ['z' for i in range(routs_num*4*bus_size)]

    for i in range(routs_num):
        for j in range(routs_num):
            if (j == i + 1) and (j % h_size != 0):
                for k in range(bus_size):
                    data_o_list[i*4*bus_size+k] = data_i[j*4*bus_size + 2*bus_size+k]
                for k in range(bus_size):
                    data_o_list[j*4*bus_size+2*bus_size+k] = data_i[i*4*bus_size+k]
            elif j == h_size + i:
                for k in range(bus_size):
                    data_o_list[i*4*bus_size+bus_size+k] = data_i[j*4*bus_size + 3*bus_size+k]
                for k in range(bus_size):
                    data_o_list[j*4*bus_size+3*bus_size+k] = data_i[i*4*bus_size+bus_size+k]
    return 'z'*add_z_n*4*bus_size + ''.join(data_o_list)[::-1]

def test_gen(bus_size, routs_num, generator, add_z_n=0, **gen_kwargs):
    res_str = str()
    ports_num = 4
    in_data = '0'*(routs_num*ports_num*bus_size-ports_num) + '1'*ports_num
    for r in range(routs_num):
        for p in range(ports_num):
            res_str += f'// {r} router {p} port\n'
            # print(in_data, in_w, out_r)
            res_str += generator(data_i=in_data,
                                routs_num=routs_num, bus_size=bus_size,
                                add_z_n=add_z_n, **gen_kwargs) + '\n'
            in_data = str_l_shift(in_data, ports_num)
    return res_str
 
if __name__ == '__main__':
    args = arg_parser_create()  # getting args
    top_types = args.top_types
    # top_types = ['circ2']
    for top_type in top_types:
        if top_type == "mesh2d":
            filename = args.path + '/' + 'mesh2d_tf.bin'
            with open(filename, 'w') as f:
                f.write('// mesh_4_2\n')
                f.write(test_gen(4, 4, mesh_2d_gen, add_z_n=9-4, h_size=2))
                f.write('// mesh_6_2\n')
                f.write(test_gen(4, 6, mesh_2d_gen, add_z_n=9-6, h_size=2))
                f.write('// mesh_6_3\n')
                f.write(test_gen(4, 6, mesh_2d_gen, add_z_n=9-6, h_size=3))
                f.write('// mesh_9_3\n')
                f.write(test_gen(4, 9, mesh_2d_gen, h_size=3))
                print(f"Test for {top_type} generated to {filename}")
        elif top_type == "circ2":
            filename = args.path + '/' + 'circ2_tf.bin'
            with open(filename, 'w') as f:
                f.write('// circ_4_1_2\n')
                f.write(test_gen(4, 4, circ2_gen, add_z_n=9-4, s0=1, s1=2))
                f.write('// circ_6_1_2\n')
                f.write(test_gen(4, 6, circ2_gen, add_z_n=9-6, s0=1, s1=2))
                f.write('// circ_9_1_2\n')
                f.write(test_gen(4, 9, circ2_gen, s0=1, s1=2))
                f.write('// circ_9_2_3\n')
                f.write(test_gen(4, 9, circ2_gen, s0=2, s1=3))
                print(f"Test for {top_type} generated to {filename}")
        else:
            print('Unknown topology type!')
