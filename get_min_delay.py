import os
import sys, linecache # for catching exceptions
import json
import argparse
import numpy as np
from scipy.optimize import curve_fit # getting approximation
from multiprocessing import Pool
from functools import partial  # need for kwargs in mapping
from itertools import groupby  # need to remove repeats in list
from target_graph import get_configs, target_modeling, title_forming, create_rt

def get_start_point(configs, jobs_num, title, rout_table_fn, first_delay=0, step=10):
    is_stop = False  # flag for stopping a cycle
    start_point = first_delay  # result
    temp_delay = first_delay   # a var for beginning in range of delays
    # kwargs preparing
    kwargs = {'config': configs, 'config_title': title, 'target_name': 'pack_delay', 'rout_table_fn': rout_table_fn}  # kwargs forming
    i = 0
    while not is_stop:  # do while working delay not founded
        # getting range with delays
        delays = list(range(temp_delay + i*step*jobs_num, temp_delay + (i+1)*step*jobs_num, step))
        with Pool(jobs_num) as pool:
            # model with jobs_num delays and get stats
            points = pool.map(partial(target_modeling, **kwargs), delays)
            for p_idx, point in enumerate(points):
                if point['packs_sended'] == point['packs_recved']:
                    is_stop = True
                    start_point = (delays[p_idx], point)
                    break
        i += 1
    return start_point

def get_correct_points(delays, config, jobs_num, title, rout_table_fn):
    result = dict()
    new_confs = config
    new_confs['packs_to_gen'] *= 5 # increase to check correct working with more packets
    kwargs = {'config': new_confs, 'config_title': title, 'target_name' : 'pack_delay', 'rout_table_fn': rout_table_fn}  # kwargs forming
    with Pool(jobs_num) as pool:
        points = pool.map(partial(target_modeling, **kwargs), delays)
        for p_idx, delay in enumerate(delays):
            if points[p_idx]['packs_sended'] == points[p_idx]['packs_recved']:
                result[delay] = points[p_idx]
            if points[p_idx]['model_time'] == new_confs['test_time']:
                raise RuntimeError("Not enough time for modeling")
    return result

def opt_n_points(a, b, f, f_args, n=4, eps=0.9):
    x_list = [int(a+((b-a)/(n-1))*i) for i in range(n)]
    x_list = [el for el, _ in groupby(x_list)]  # removing repeats in list
    y_list = [f(x, *f_args) for x in x_list]

    min_idx = 0
    min_1_idx = 1
    for idx, y in enumerate(y_list):
        if abs(y) > eps and abs(y_list[min_idx]) > abs(y):
            min_1_idx = min_idx
            min_idx = idx
    
    if abs(x_list[min_idx] - x_list[min_1_idx]) == 1:
        return x_list[min_idx], y_list[min_idx]
    elif x_list[min_idx] < x_list[min_1_idx]:
        return opt_n_points(x_list[min_idx], x_list[min_1_idx], f, f_args, n, eps)
    elif x_list[min_idx] > x_list[min_1_idx]:
        return opt_n_points(x_list[min_1_idx], x_list[min_idx], f, f_args, n, eps)

def print_exception():
    exc_type, exc_obj, tb = sys.exc_info()
    f = tb.tb_frame
    lineno = tb.tb_lineno
    filename = f.f_code.co_filename
    linecache.checkcache(filename)
    line = linecache.getline(filename, lineno, f.f_globals)
    print('EXCEPTION IN ({}, LINE {} "{}"): {}'.format(filename, lineno, line.strip(), exc_obj))

def target_f(x, a, b, c, d):
    return a/np.log(b*x+c)+d

def d_f(x, a, b, c):
    return -(a*b)/((b*x+c)*(np.log(b*x+c))**2)

def optimization(configs, jobs_num, eps_pow=8):
    if eps_pow <= 1 or eps_pow == 10:
        raise ValueError("Wrong ")
    results = dict()
    # find minimal working delay for all configs
    for config in configs:
        title = title_forming(config, 'pack_delay')  # used as name for logfiles
        rout_table_fn = create_rt(config)  # create routing table
        # getting saved dump
        try:
            dump_dict = dict()
            with open(f"opt_dump_{title}.json", 'r') as f:
                dump_dict = json.load(f)
            if 'start_point' in dump_dict:
                dump_dict.pop('start_point')
            first_delay = int(dump_dict['first_delay'])
            second_delay = int(dump_dict['second_delay'])
            n_delays = [int(first_delay+((second_delay-first_delay)/(jobs_num-1))*i) for i in range(jobs_num)]
            if 'popt' not in dump_dict:
                app_points = dump_dict['app_points']  # for old dumps
                popt, _ = curve_fit(target_f, n_delays, [x['mean_time'] for x in app_points], maxfev=5000)
                dump_dict['popt'] = popt
                dump_dict.pop('app_points')
            else: 
                popt = dump_dict['popt']
            eps_incr = dump_dict['eps_incr']
            checked_delays = dump_dict['checked_delays']
            print(f"Loaded {dump_dict} from opt_dump_{title}.json")
        except FileNotFoundError:
            print(f"Couldn't load from opt_dump_{title}.json, start modeling")
            start_point = get_start_point(config, jobs_num, title, rout_table_fn=rout_table_fn, step=1)  # getting first working delay
            first_delay = start_point[0] # first point of a segment
            second_delay = first_delay + 1000 # second
            eps_incr = 0 # parameter for eps**eps_incr
            print(f"Getting {jobs_num} points for approximation:")
            n_delays = [int(first_delay+((second_delay-first_delay)/(jobs_num-1))*i) for i in range(jobs_num)]
            with Pool(jobs_num) as pool:
                kwargs = {'config': config, 'config_title': title, 'target_name' : 'pack_delay', 'rout_table_fn': rout_table_fn}  # kwargs forming
                # model with jobs_num delays and get stats
                app_points = pool.map(partial(target_modeling, **kwargs), n_delays)
            # approximating by jobs_num points            
            popt, _ = curve_fit(target_f, n_delays, [x['mean_time'] for x in app_points], maxfev=5000)
            checked_delays = list() # saving to eliminate re-modeling
            dump_dict = {
                'first_delay': first_delay,
                'second_delay' : second_delay,
                'popt' : list(popt),
                'eps_incr' : eps_incr,
                'checked_delays' : checked_delays
            }
            # saving dump
            with open(f"opt_dump_{title}.json", 'w') as f:
                json.dump(dump_dict, f)
            print(f"Dumped to opt_dump_{title}.json")
        except Exception as e:
            print_exception()
        print(f"First delay: {first_delay}\nSecond delay: {second_delay}")
        print(f"Eps increase index: {eps_incr}")
        try:
            # find while temp minimum can't receive more packets
            delays_to_check = list()
            if first_delay not in dump_dict['checked_delays']:
                delays_to_check.append(first_delay)
            min_points = dict()
            while not min_points:
                # get jobs_num delays to check
                while len(delays_to_check) < jobs_num:
                    new_min = opt_n_points(a=first_delay, b=second_delay,
                                           f=d_f, f_args=popt[:-1], n=jobs_num, eps=np.log10(eps_pow)**eps_incr)
                     # check if min element in the rigth border
                    if new_min[0] == second_delay:
                        first_delay += 1000
                        second_delay += 1000
                    if new_min[0] not in delays_to_check and new_min[0] not in dump_dict['checked_delays']:
                        delays_to_check.append(new_min[0])
                    eps_incr += 1
                    
                print(f"Delays to check: {delays_to_check}")
                min_points = get_correct_points(delays_to_check, config, jobs_num, title, rout_table_fn)
                dump_dict['checked_delays'].extend(delays_to_check)
                if min_points and dump_dict['checked_delays'].index(min(min_points)) > 0:
                    first_delay = dump_dict['checked_delays'][dump_dict['checked_delays'].index(min(min_points))-1]
                    second_delay = min(min_points)
                    mins = [opt_n_points(first_delay+1, second_delay-1, d_f, popt[:-1], jobs_num, np.log10(eps_pow)**i)
                            for i in range(0, eps_incr**2)]
                    delays_to_check = [el[0] for el, _ in groupby(mins)]
                    print(f"Delays to check: {delays_to_check}")
                    min_points.update(get_correct_points(delays_to_check, config, jobs_num, title, rout_table_fn))
                    dump_dict['checked_delays'].extend(delays_to_check)
                # dumping
                dump_dict['eps_incr'] = eps_incr 
                delays_to_check = list()  # clear for next iteration
            min_delay = min(min_points)
            results[title] = {
                'delay' : min_delay,
                'point' : min_points[min_delay]
            } # save founded minimum
            print(f"Founded minimum delay for {title} is {min_delay} with {min_points[min_delay]['mean_time']:.2f} mean receive time")
        # except Exception as e:
        #     print_exception()
        finally:
            os.remove(rout_table_fn)
            # saving dump
            with open(f"opt_dump_{title}.json", 'w') as f:
                json.dump(dump_dict, f)
    return results

def args_parse():
    parser = argparse.ArgumentParser(description="Script to get mininal working delay")
    parser.add_argument('settings_file', type=str, help="Path to a file with initial parameters.")
    parser.add_argument('--savefile', type=str, default="opt_results.json", help="Path to a file with results.")
    parser.add_argument('-n', '--jobs_num', default=os.cpu_count(), type=int, help="A number of jobs.")
    args = parser.parse_args()
    return args

def run():
    args = args_parse()
    configs = get_configs(args.settings_file)
    # getting args
    if not configs:
        return None
    results = optimization(configs, args.jobs_num, eps_pow=8)
    with open(args.savefile, 'w') as f:
        json.dump(results, f)    

if __name__ == "__main__":
    run()