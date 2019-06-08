import json
from rout_table_gen import mesh_rt_gen, circ2_ROU_gen, torus_rt_gen, rout_table_to_str

def get_configs(json_file):
    configs = list()
    # getting parameters from json
    try:
        with open(json_file, 'r') as r_file:
            configs = json.load(r_file)  # must be array with params
    except FileNotFoundError:
        print("File not found. Try another path")
    # stop modeling if params are broken and continue with accepted
    if not check_configs(configs):
        return None
    return configs

def create_rt(configs):
    # creating a routing table
    rout_table_fn = title_forming(configs) + ".srtf"
    if configs['topology'] == "mesh_2d":
        routing_table = mesh_rt_gen(configs['nodes_num'], configs['h_size'])
    elif configs['topology'] == "torus":
        routing_table = torus_rt_gen(configs['nodes_num'], configs['h_size'])
    elif configs['topology'] == "circulant_2":
        routing_table = circ2_ROU_gen(configs['nodes_num'], configs['s0'], configs['s1'])
    with open(rout_table_fn, 'w') as file:
        file.write(rout_table_to_str(routing_table, transpose=False, invert=True))
    return rout_table_fn

def check_configs(configs):
    return True  # TODO: make checking

def title_forming(config, target_name=None):
    if config['topology'] == 'mesh_2d' or config['topology'] == 'torus':
        config_title = f"{config['topology']}_{config['nodes_num']}_{config['h_size']}"
    elif config['topology'] == 'circulant_2':
        config_title = f"{config['topology']}_{config['nodes_num']}_{config['s0']}_{config['s1']}"
    else:
        print("Unknown topology!")
    if target_name:
        config_title += f"_{target_name}"
    return config_title

def save_dict(dict_to_save, filename):
    with open(filename, 'w') as f:
        json.dump(dict_to_save, f)
