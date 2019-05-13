import os
import sys, linecache # for catching exceptions
import json
import argparse
import numpy as np
from scipy.optimize import curve_fit # getting approximation
from multiprocessing import Pool
from functools import partial  # need for kwargs in mapping
from itertools import groupby  # need to remove repeats in list
from target_graph import get_configs, target_modeling, title_forming

def get_start_point(configs, jobs_num, title, first_delay=0, step=10):
    is_stop = False  # flag for stopping a cycle
    start_point = first_delay  # result
    temp_delay = first_delay   # a var for beginning in range of delays
    # kwargs preparing
    kwargs = {'config': configs, 'config_title': title, 'target_name' : 'pack_delay'}  # kwargs forming
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

def check_delay(min_delay, config, jobs_num, title, is_checked=False, check_res=False):
    # if have checking results
    if is_checked:
        return check_res
    # get different packets num
    packet_nums = [config['packs_to_gen']*(i+2) for i in range(jobs_num)]
    config['pack_delay'] = min_delay
    kwargs = {'config': config, 'config_title': title, 'target_name' : 'packs_to_gen'}  # kwargs forming
    with Pool(jobs_num) as pool:
        points = pool.map(partial(target_modeling, **kwargs), packet_nums)
        for p_idx, point in enumerate(points):
            if point['packs_sended'] != point['packs_recved']:
                return False
    return True

def opt_n_points(a, b, f, f_args, n=4, eps=0.01):
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

def optimization(configs, jobs_num, eps=0.75):
    results = dict()
    # for saving results
    
    # find minimal working delay for all configs
    for config in configs:
        title = title_forming(config, 'pack_delay')  # used as name for logfiles
        # for approximating
        # getting saved dump
        try:
            dump_dict = dict()
            with open(f"opt_dump_{title}.json", 'r') as f:
                dump_dict = json.load(f)
            start_point =  dump_dict['start_point']
            min_point = dump_dict['mins'][-1]
            first_delay = int(dump_dict['first_delay'])
            second_delay = int(dump_dict['second_delay'])
            n_delays = [int(first_delay+((second_delay-first_delay)/(jobs_num-1))*i) for i in range(jobs_num)]
            is_checked = bool(dump_dict['is_checked'])
            check_res = bool(dump_dict['check_res'])
            app_points = dump_dict['app_points']
            print(f"Loaded from opt_dump_{title}.json")
        except FileNotFoundError:
            print(f"Couldn't load from opt_dump_{title}.json, start modeling")
            start_point = get_start_point(config, jobs_num, title, step=1)  # getting first working delay
            min_point = start_point # now it is first minimal delay
            first_delay = start_point[0] # first point of a segment
            second_delay = first_delay + 1000 # second
            print(f"Getting {jobs_num} points for approximation:")
            n_delays = [int(first_delay+((second_delay-first_delay)/(jobs_num-1))*i) for i in range(jobs_num)]
            with Pool(jobs_num) as pool:
                kwargs = {'config': config, 'config_title': title, 'target_name' : 'pack_delay'}  # kwargs forming
                # model with jobs_num delays and get stats
                app_points = pool.map(partial(target_modeling, **kwargs), n_delays)
            dump_dict = {
                'start_point': start_point,
                'mins': [min_point],
                'first_delay': first_delay,
                'second_delay' : second_delay,
                'is_checked' : False,
                'check_res' : False,
                'app_points' : app_points
            }
            # saving dump
            with open(f"opt_dump_{title}.json", 'w') as f:
                json.dump(dump_dict, f)
            print(f"Dumped to opt_dump_{title}.json")
        try:
            # approximating by jobs_num points            
            popt, _ = curve_fit(target_f, n_delays, [x['mean_time'] for x in app_points])
            eps_incr = 0 # parameter for eps**eps_incr
            # find while temp minimum can't receive more packets
            print(f"Check first delay: {min_point[0]}")
            while not check_delay(min_point[0], config, jobs_num, title, dump_dict['is_checked'], dump_dict['check_res']):
                dump_dict['is_checked'] = True
                dump_dict['check_res'] = False
                prev_min = min_point
                min_point = opt_n_points(a=first_delay, b=second_delay, f=d_f, f_args=popt[:-1], n=jobs_num, eps=eps**eps_incr)
                print(f"New minimum is {min_point[0]} with eps = {eps**eps_incr}")
                dump_dict['is_checked'] = True if min_point[0] == prev_min[0] else False
                eps_incr += 1
                dump_dict['mins'].append(min_point)
                if min_point[0] == second_delay:
                    second_delay += 1000
            dump_dict['is_checked'] = True
            dump_dict['check_res'] = True
            results[title] = { # save founded minimum
                'delay': min_point[0],
                'mean_recv_time': target_f(min_point[0], *popt),
                'grad': min_point[1]
                }
            print(f"Founded minimum delay for {title} is {min_point[0]} with {target_f(min_point[0], *popt)} mean receive time")
        except Exception as e:
            print_exception()
        finally:    # saving dump
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
    results = optimization(configs, args.jobs_num, eps=0.75)
    with open(args.savefile, 'w') as f:
        json.dump(results, f)    

if __name__ == "__main__":
    run()