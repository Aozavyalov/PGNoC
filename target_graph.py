import json
import argparse
import os
from multiprocessing import Pool
from functools import partial  # for using kwargs with mapping
import matplotlib.pyplot as plt

from rout_table_gen import mesh_rt_gen, circ2_rt_gen, torus_rt_gen, rout_table_to_str
from NoC_stats import parse_logs

def run_sim(configs, **kwargs):
    config_title = kwargs.get('config_title')
    # creating a routing table
    if configs['topology'] == "mesh_2d":
        routing_table = mesh_rt_gen(configs['nodes_num'], configs['h_size'])
    elif configs['topology'] == "torus":
        routing_table = torus_rt_gen(configs['nodes_num'], configs['h_size'])
    elif configs['topology'] == "circulant_2":
        routing_table = circ2_rt_gen(configs['nodes_num'], configs['s0'], configs['s1'])
    rout_table_path = kwargs.get("rt_path", "rout_table.srtf")
    with open(rout_table_path, 'w') as file:
        file.write(rout_table_to_str(routing_table, transpose=False, invert=True))
    # forming definitions string
    definitions = f"+define+configs+{configs['topology'].upper()}+DEBUG=0+RT_PATH=\\\"../{rout_table_path}\\\""
    for key in configs:
        if key != "topology":
            if isinstance(configs[key], str):
                definitions += f'+{key.upper()}=\\\"{kwargs.get(key, configs[key])}\\\"'
            else:
                definitions += f'+{key.upper()}={kwargs.get(key, configs[key])}'
    # recreating "sim" directory
    os.system("@echo off")
    os.system(f"rd /s /q sim-{config_title} >nul 2>&1")  # it will remove (or not, if doesn't exist) "sim" dir silently
    os.mkdir(f"sim-{config_title}")
    os.chdir(f"sim-{config_title}")
    # execute simulation
    os.system("vlib work")
    os.system(f'vlog -nologo {definitions} ../src/connector/*.v \
                ../src/switch/*.v ../src/IP/*.v ../tests/testbenches/test_NoC_tb.v >nul 2>&1')
    os.system('vsim -onfinish exit work.test_NoC_tb -do \"run -all\" >nul 2>&1')
    # clear after sim finished
    os.chdir("..")
    os.system(f"rd /s /q sim-{config_title}")
    os.remove(rout_table_path)
    
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

# function for mapping delays
def target_modeling(val, **kwargs):
    # pool_logfile = kwargs.get("pool_logfile")
    config = kwargs.get('config')
    config_title = f"{kwargs.get('config_title')}-{val}"
    target_name = kwargs.get('target_name')
    pool_logfile = f"log-{val}" # logfile name
    rt_path = f"rt-{val}.srtf"
    try:
        if not os.path.isfile(pool_logfile):  # if log exists, dont run sim again
            print(f"Running {target_name} = {val}...")
            sim_kwargs = dict()
            config[target_name] = val
            sim_kwargs['logs_path'] = f"../{pool_logfile}"
            sim_kwargs['config_title'] = config_title  # need for creating uniqe folder
            sim_kwargs['rt_path'] = rt_path
            run_sim(config, **sim_kwargs)
        stats = parse_logs(pool_logfile)
        os.remove(pool_logfile) # remove log file after processing
    except KeyboardInterrupt:
        print(f"Modeling {config_title} has been stopped")
        return
    return stats

def check_configs(configs):
    return True  # TODO: make checking

def title_forming(config, target_name):
    if config['topology'] == 'mesh_2d' or config['topology'] == 'torus':
        config_title = f"{config['topology']}_{config['nodes_num']}_{config['h_size']}_{target_name}"
    elif config['topology'] == 'circulant_2':
        config_title = f"{config['topology']}_{config['nodes_num']}_{config['s0']}_{config['s1']}_{target_name}"
    else:
        print("Unknown topology!")
    return config_title

def args_parse():
	parser = argparse.ArgumentParser(description="Script to get delay graphs with mean receive times and modeling times")
	parser.add_argument('settings_file', type=str, help="Path to a file with initial parameters.")
	parser.add_argument('-n', '--jobs_num', default=os.cpu_count(), type=int, help="A number of jobs.")
	args = parser.parse_args()
	return args

def make_graph(configs, target_name, target_vals, jobs_num=1):
    results = dict()
    for config in configs:
        # title forming
        config_title = title_forming(config, target_name)
        results[config_title] = dict()
        # header and other params
        results[config_title]['target_name'] = target_name
        results[config_title]['target_vals'] = target_vals
        results[config_title]['configs'] = config
        results[config_title]['mean_recv_times'] = list()
        # indexes where sended packs = recved packs
        results[config_title]['working_indexes'] = list()
        results[config_title]['modeling_times']  = list()
        
        if os.path.isfile(f"dumpfile_{config_title}.json"):
            # try to load results from a dump
            with open(f"dumpfile_{config_title}.json", 'r') as dumpfile:
                dump = json.load(dumpfile)
            # check if the dump has the same configs
            if results[config_title]['target_vals'] == dump['target_vals'] and results[config_title]['configs'] == dump['config']:
                results[config_title]['mean_recv_times'] = dump['mean_recv_times']
                results[config_title]['modeling_times']  = dump['modeling_times']
                results[config_title]['working_indexes'] = dump['working_indexes']
        # if not loaded, start modeling
        if not (results[config_title]['mean_recv_times'] and
                results[config_title]['modeling_times'] and 
                results[config_title]['working_indexes']):
            kwargs = {'config': config, 'config_title': config_title, 'target_name' : target_name}  # kwargs forming
            with Pool(jobs_num) as pool:
                stats = pool.map(partial(target_modeling, **kwargs), target_vals)
        
            # getting mean_time, model_time and correct points
            for delay_idx, stat in enumerate(stats):
                results[config_title]['mean_recv_times'].append(stat['mean_time'])
                results[config_title]['modeling_times'].append(stat['model_time'])
                if stat['packs_sended'] == stat['packs_recved']:
                    results[config_title]['working_indexes'].append(delay_idx)
        
    return results

def plotting(graphs, points=None):
    for config_title in graphs:
        target_vals = graphs[config_title]['target_vals']
        mean_recv_times = graphs[config_title]['mean_recv_times']
        modeling_times  = graphs[config_title]['modeling_times']
        working_indexes = graphs[config_title]['working_indexes']

        # plotting
        plt.figure(figsize=(10, 7))
        plt.subplot(2, 1, 1)
        plt.xlabel(graphs[config_title]['target_name'])
        plt.ylabel("mean receiving time")
        plt.plot(target_vals, mean_recv_times, 'b-', label="all results")
        plt.scatter([target_vals[i] for i in working_indexes],
                    [mean_recv_times[i] for i in working_indexes], marker='.', c='r',
                    label="correct results")
        plt.legend(loc='best')
        plt.subplot(2, 1, 2)
        plt.plot(target_vals, modeling_times, 'b-', label="all results")
        plt.scatter([target_vals[i] for i in working_indexes],
                    [modeling_times[i] for i in working_indexes], marker='.', c='r',
                    label="correct results")
        plt.xlabel(graphs[config_title]['target_name'])
        plt.ylabel("modeling time")
        plt.legend(loc='best')
        plt.subplots_adjust(wspace=0, hspace=0.3)
        # saving as image
        plt.savefig(config_title + ".png")

if __name__ == "__main__":
    args = args_parse()
    configs = get_configs(args.settings_file)
    step = 10
    min_delay = 0
    max_delay = 1000
    delays = list(range(min_delay, max_delay+1, step))
    target_name = 'pack_delay'
    if configs:
        graphs = make_graph(configs, target_name, delays, jobs_num=args.jobs_num)
        # saving
        for title in graphs:
            with open(f"dumpfile_{title}.json", 'w') as f:
                json.dump(graphs[title], f)
        plotting(graphs)  # plot all graphs
        print("Finished")
