import argparse
import os
import platform
from multiprocessing import Pool
from utils import get_configs, title_forming, create_rt, save_dict
from stats import parse_logs

def start_win(config_title, definitions, logs_path):
	try:
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
    except KeyboardInterrupt:
        # clear after sim finished
        os.remove(kwargs.get(logs_path))  # remove logfile
        os.chdir("..")
        os.system(f"rd /s /q sim-{config_title}") # remove sim folder

def start_linux(config_title, definitions, logs_path):
	try:
        # recreating "sim" directory
        os.system(f"rm -rf sim-{config_title} 2>&1")  # it will remove (or not, if doesn't exist) "sim" dir silently
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
    except KeyboardInterrupt:
        # clear after sim finished
        os.remove(kwargs.get(logs_path))  # remove logfile
        os.chdir("..")
        os.system(f"rm -rf sim-{config_title}") # remove sim folder

def run_sim(configs, **kwargs):
    config_title = kwargs.get('config_title')
    rout_table_fn = kwargs.get("rout_table_fn")
    if not (rout_table_fn and os.path.isfile(rout_table_fn)):
        raise FileNotFoundError(f"File \"{rout_table_fn}\" doesn't exists")
    # forming definitions string
    definitions = f"+define+configs+{configs['topology'].upper()}+DEBUG=0+RT_PATH=\\\"../{rout_table_fn}\\\""
    for key in configs:
        if key != "topology":
            if isinstance(configs[key], str):
                definitions += f'+{key.upper()}=\\\"{kwargs.get(key, configs[key])}\\\"'
            else:
                definitions += f'+{key.upper()}={kwargs.get(key, configs[key])}'
    os_type = platform.system()
    if os_type == "Windows":
   		start_win(config_title, definitions, logs_path)
   	elif os_type == "Linux":
   		start_win(config_title, definitions, logs_path)
   	else:
   		print("Unexpected OS used. Please, use Windows or Linux")

def args_parse():
	parser = argparse.ArgumentParser(description="Script to get mininal working delay")
	parser.add_argument('settings_file', type=str, help="Path to a file with initial parameters.")
	parser.add_argument('--savefile', type=str, default="opt_results.json", help="Path to a file with results.")
	parser.add_argument('-n', '--jobs_num', default=os.cpu_count(), type=int, help="A number of jobs.")
	args = parser.parse_args()
	return args

def run_sim_kwargs(kwargs):
	return run_sim(**kwargs)

def main():
	args = args_parse()
	configs_list = get_configs(args.settings_file)
	# creating kwargs for mapping
	kwargs_list = list()
	for i, configs in enumerate(configs_list):
		conf_title = title_forming(configs)
		kwargs = {
			'configs' : configs,
			'config_title' : conf_title,
			'rout_table_fn' : create_rt(configs),
			'logs_path' : f"../logs-{conf_title}-{i}"
		}
		kwargs_list.append(kwargs)

	res_dict = dict()
	with Pool(os.cpu_count()) as pool:
		pool.map(run_sim_kwargs, kwargs_list)

	for i, kw in enumerate(kwargs_list):
		os.remove(kw['rout_table_fn'])
		logfile = kw['logs_path'][3:]
		if os.path.isfile(logfile):
			res_dict[kw['config_title']] = parse_logs(logfile)
			os.remove(logfile) # remove log file after processing
	
	save_dict(res_dict, "model_results.json")

if __name__ == '__main__':
	main()
