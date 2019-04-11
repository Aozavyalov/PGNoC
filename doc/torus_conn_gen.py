def torus_gen_conn(nodes_num, h_size):
    conn_table = [['-' for j in range(nodes_num)] for i in range(nodes_num)]
    for i in range(nodes_num):
        for j in range(nodes_num):
            if (j == i + 1 and i % h_size != h_size - 1) or (i % h_size == h_size - 1 and i-j-h_size+1 == 0):
                conn_table[i][j] = '0'
                conn_table[j][i] = '2'
            elif j == i + h_size or nodes_num - i + j == h_size:
                conn_table[i][j] = '1'
                conn_table[j][i] = '3'
    return conn_table

if __name__ == "__main__":
    nodes_num = int(input())
    conn_table = torus_gen_conn(nodes_num, int(input()))
    for src_list in conn_table:
        for port in src_list:
            print(port, end=' ')
        print()
