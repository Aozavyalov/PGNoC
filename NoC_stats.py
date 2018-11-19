import argparse
import re
import pandas as pd
from os import listdir

def arg_parser_create():
    parser = argparse.ArgumentParser(description="Script for getting statistics of NoC work from generated files.")
    parser.add_argument('logs_path', type=str, help="Path to a folder with logs.")
    parser.add_argument('-l', '--data_len', default=38, type=int, help="Length of data.")
    parser.add_argument('-s', '--savefile', type=str, nargs='?', help="File to save statistics. If not specified, it will print to console.")
    args = parser.parse_args()
    return args

def parse_logs(path_to_logs, flit_len=38):
  logs = pd.DataFrame(columns=['time', 'node', 'gen', 'recv', 'gen_flit', 'recv_flit'])
  files_to_read = listdir(path_to_logs)
  # for logname in files_to_read:
  #   with open(f"{path_to_logs}/{logname}", 'r') as logfile:
      
  return logs

def make_stats(logs):
  stats = {
    "nodes"      : 0,
    "packs_gen": 0,
    "flits_sended": 0,
    "flits_recv": 0,
    "wrong_flits": 0,
    "mean_time" : 0
  }
  
  return stats

def result_former(res_dict):
  pass

if __name__ == "__main__":
  args = arg_parser_create()
  logs = parse_logs(args.logs_path, data_len)
  # stats = make_stats(logs)
  # print(stats)
  # res_string = result_former(stats)
  # if args.savefile:
  #   with open(args.savefile, 'w') as savefile:
  #     savefile.write(res_string)
  # else:
  #   print(res_string)
