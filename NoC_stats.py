import argparse
from os import listdir

def arg_parser_create():
    parser = argparse.ArgumentParser(description="Script for getting statistics of NoC work from generated files.")
    parser.add_argument('logs_path', type=str, help="Path to a folder with log.")
    parser.add_argument('-f', '--flit_len', default=38, type=int, help="Length of flit.")
    parser.add_argument('-s', '--savefile', type=str, nargs='?', help="File to save statistics. If not specified, it will print to console.")
    args = parser.parse_args()
    return args

def parse_logs(path_to_logs, flit_len=38):
  logs = list()
  files_to_read = listdir(path_to_logs)
  for logname in files_to_read:
    with open(f"{path_to_logs}/{logname}", 'r') as logfile:
      for line in logfile:
        log = dict()
        splitted = line.split('|')
        log['time'] = int(splitted[0])
        log['addr'] = int(splitted[1], base=16)
        log['stat'] = splitted[2]
        if log['stat'] == "new package":
          log['pack_len'] = int(splitted[3].split()[1], base=16)
          log['dest_addr'] = int(splitted[4].split()[1], base=16)
        elif log['stat'] == "flit sended":
          log['flit'] = splitted[3][-2::-1]  # reverse for better usability
        elif log['stat'] == "package sended":
          log['packs_sended'] = int(splitted[3])
        elif log['stat'] == "finish generating":
          log['packs_sended'] = int(splitted[3])
        elif log['stat'] == "recved flit":
          log['flit_num'] = int(splitted[3]) + 1
          log['flit'] = splitted[4][-2::-1]
        elif log['stat'] == "recved wrong flit":
          log['real_addr'] = splitted[3].split()[1]
          log['flit'] = splitted[4][-2::-1]
        elif log['stat'] == "recved package":
          log['packs_recv'] = int(splitted[3].split()[1])
        logs.append(log)
  return logs

def make_stats(logs):
  nodes = dict()
  flits_send_time = dict()
  for log in sorted(logs, key=lambda log: log['time']):
    # print(log)
    if log['addr'] not in nodes:
      nodes[log['addr']] = {
        "flits_sended": 0,
        "flits_recv"  : 0,
        "packs_sended": 0,
        "packs_recved": 0,
        "wrong_flits" : 0,
        "mean_time"   : 0
      }
    if log['stat'] == "flit sended":
      nodes[log['addr']]['flits_sended'] += 1
      flits_send_time[log['flit']] = log['time']
    elif log['stat'] == "recved flit":
      nodes[log['addr']]['flits_recv'] += 1
      nodes[log['addr']]['mean_time'] += (log['time'] - flits_send_time[log['flit']])
      flits_send_time.pop(log['flit'])
    elif log['stat'] == "recved wrong flit":
      nodes[log['addr']]['wrong_flits'] += 1
    elif log['stat'] == "package sended":
      nodes[log['addr']]['packs_sended'] += 1
    elif log['stat'] == "recved package":
      nodes[log['addr']]['packs_recved'] += 1
  for key in nodes:
    nodes[key]['mean_time'] = nodes[key]['mean_time'] / nodes[key]['flits_recv']
  return nodes

def result_former(res_dict):
  res_str = str()
  all_flits_sended   = 0
  all_flits_received = 0
  all_packs_sended   = 0
  all_packs_received = 0
  all_wrong_flits    = 0
  all_mean_time      = 0
  for key in sorted(res_dict):
    res_str += f'{key} node:\n'
    for param in sorted(res_dict[key]):
      if param == 'flits_sended':
        res_str += f"\tflits sended: {res_dict[key][param]}\n"
        all_flits_sended += res_dict[key][param]
      elif param == 'flits_recv':
        res_str += f"\tflits received: {res_dict[key][param]}\n"
        all_flits_received += res_dict[key][param]
      elif param == 'packs_sended':
        res_str += f"\tpackets sended: {res_dict[key][param]}\n"
        all_packs_sended += res_dict[key][param]
      elif param == 'packs_recved':
        res_str += f"\tpackets received: {res_dict[key][param]}\n"
        all_packs_received += res_dict[key][param]
      elif param == 'wrong_flits':
        res_str += f"\twrong flits received: {res_dict[key][param]}\n"
        all_wrong_flits += res_dict[key][param]
      elif param == 'mean_time':
        res_str += f"\tMean flit receive time: {res_dict[key][param]}\n"
        all_mean_time += res_dict[key][param]
  all_mean_time = all_mean_time / len(res_dict.keys())
  res_str += "All stats:\n"
  res_str += f"\tflits sended: {all_flits_sended}\n"
  res_str += f"\tflits received: {all_flits_received}\n"
  res_str += f"\tpackets sended: {all_packs_sended}\n"
  res_str += f"\tpackets received: {all_packs_received}\n"
  res_str += f"\twrong flits received: {all_wrong_flits}\n"
  res_str += f"\tMean flit receive time: {all_mean_time}\n"
  return res_str

if __name__ == "__main__":
  args = arg_parser_create()
  logs = parse_logs(args.logs_path)
  stats = make_stats(logs)
  res_string = result_former(stats)
  if args.savefile:
    with open(args.savefile, 'w') as savefile:
      savefile.write(res_string)
  else:
    print(res_string)
