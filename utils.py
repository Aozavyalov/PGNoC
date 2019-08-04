import json
import logging
from rout_table_gen import mesh_rt_gen, circ2_ROU_gen, torus_rt_gen, rout_table_to_str

def get_configs(json_filename):
    configs = list()
    # getting parameters from json
    try:
        with open(json_filename, 'r') as r_file:
            configs = json.load(r_file)  # must be array with params
    except FileNotFoundError:
        print("File not found. Try another path")
    except:
        print("Exception while trying to load json-configs")
    return configs if check_configs(configs) else None

def create_rt_file(configs, mode='h'):
    # creating a routing table
    # hrtf - hex routing table file
    rout_table_filename = title_forming(configs) + ".hrtf"
    if configs['topology'] == "mesh_2d":
        routing_table = mesh_rt_gen(configs['nodes_num'], configs['h_size'])
    elif configs['topology'] == "torus":
        routing_table = torus_rt_gen(configs['nodes_num'], configs['h_size'])
    elif configs['topology'] == "circulant_2":
        routing_table = circ2_ROU_gen(configs['nodes_num'], configs['s0'], configs['s1'])
    else:
        print("Unknown topology used in configs")
        return None
    with open(rout_table_fn, 'w') as file:
        rt_str = rout_table_to_str(rout_table_filename, transpose=False, invert=True)
        file.write(rt_str)
    return rout_table_filename

def check_configs(configs):
    return True  # TODO: make checking

def title_forming(config, ending=str()):
    config_title = str()
    if config['topology'] == 'mesh_2d' or config['topology'] == 'torus':
        config_title = f"{config['topology']}_{config['nodes_num']}_{config['h_size']}"
    elif config['topology'] == 'circulant_2':
        config_title = f"{config['topology']}_{config['nodes_num']}_{config['s0']}_{config['s1']}"
    else:
        print("Unknown topology!")
    return '_'.join((config_title, ending)) if ending else config_title

def save_dict(dict_to_save, filename):
    with open(filename, 'w') as f:
        json.dump(dict_to_save, f)
