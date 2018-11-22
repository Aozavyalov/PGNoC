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
  stats = { "flits_sended": 0,
            "flits_recv"  : 0,
            "packs_sended": 0,
            "packs_recved": 0,
            "wrong_flits" : 0,
            "mean_time"   : 0,
            "nodes" : dict()
          }
  flits_send_time = dict()
  for log in sorted(logs, key=lambda log: log['time']):
    # print(log)
    if log['addr'] not in stats['nodes']:
      stats['nodes'][log['addr']] = {
        "flits_sended": 0,
        "flits_recv"  : 0,
        "packs_sended": 0,
        "packs_recved": 0,
        "wrong_flits" : 0,
        "mean_time"   : 0,
        "last_flit_send_time" : 0,
        "last_flit_recv_time" : 0,
      }
    if log['stat'] == "flit sended":
      stats['nodes'][log['addr']]['flits_sended'] += 1
      flits_send_time[log['flit']] = log['time']
      stats['nodes'][log['addr']]['last_flit_send_time'] = log['time'] - 1
    elif log['stat'] == "recved flit":
      stats['nodes'][log['addr']]['flits_recv'] += 1
      stats['nodes'][log['addr']]['mean_time'] += (log['time'] - flits_send_time[log['flit']])
      flits_send_time.pop(log['flit'])
      stats['nodes'][log['addr']]['last_flit_recv_time'] = log['time'] - 1
    elif log['stat'] == "recved wrong flit":
      stats['nodes'][log['addr']]['wrong_flits'] += 1
    elif log['stat'] == "package sended":
      stats['nodes'][log['addr']]['packs_sended'] += 1
    elif log['stat'] == "recved package":
      stats['nodes'][log['addr']]['packs_recved'] += 1
  for node in stats['nodes']:
    stats['nodes'][node]['mean_time'] = stats['nodes'][node]['mean_time'] / stats['nodes'][node]['flits_recv']
  # all stats
  for node in stats['nodes']:
    for param in stats['nodes'][node]:
      if param == 'flits_sended':
        stats['flits_sended'] += stats['nodes'][node][param]
      elif param == 'flits_recv':
        stats['flits_recv'] += stats['nodes'][node][param]
      elif param == 'packs_sended':
        stats['packs_sended'] += stats['nodes'][node][param]
      elif param == 'packs_recved':
        stats['packs_recved'] += stats['nodes'][node][param]
      elif param == 'wrong_flits':
        stats['wrong_flits'] += stats['nodes'][node][param]
      elif param == 'mean_time':
        stats['mean_time'] += stats['nodes'][node][param]
  # stats['model_time'] = sorted(logs, key=lambda log: log['time'])[-1]['time'] - 1 # 1 cycle for resetting
  stats['model_time'] = max([stats['nodes'][node]['last_flit_recv_time'] for node in stats['nodes']])
  stats['mean_time'] = stats['mean_time'] / len(stats['nodes'].keys())
  stats['fir'] = stats['flits_sended'] / stats['model_time'] / len(stats['nodes'].keys())
  return stats

def result_former(stats):
  res_str = str()
  res_str += "All stats:\n"
  res_str += f"\tModeling time: {stats['model_time']}\n"
  res_str += f"\tFlits injection rate: {stats['fir']}\n"
  res_str += f"\tFlits sended: {stats['flits_sended']}\n"
  res_str += f"\tFlits received: {stats['flits_recv']}\n"
  res_str += f"\tPackets sended: {stats['packs_sended']}\n"
  res_str += f"\tPackets received: {stats['packs_recved']}\n"
  res_str += f"\tWrong flits received: {stats['wrong_flits']}\n"
  res_str += f"\tMean flit receive time: {stats['mean_time']}\n"
  for node in sorted(stats['nodes']):
    res_str += f"{node} node\n"
    res_str += f"\tFlits sended: {stats['nodes'][node]['flits_sended']}\n"
    res_str += f"\tFlits received: {stats['nodes'][node]['flits_recv']}\n"
    res_str += f"\tPackets sended: {stats['nodes'][node]['packs_sended']}\n"
    res_str += f"\tPackets received: {stats['nodes'][node]['packs_recved']}\n"
    res_str += f"\tWrong flits received: {stats['nodes'][node]['wrong_flits']}\n"
    res_str += f"\tMean flit receive time: {stats['nodes'][node]['mean_time']}\n"
    res_str += f"\tLast flit sended in {stats['nodes'][node]['last_flit_send_time']} time\n"
    res_str += f"\tLast flit received in {stats['nodes'][node]['last_flit_recv_time']} time\n"
  return res_str

if __name__ == "__main__":
  args = arg_parser_create()
  logs = parse_logs(args.logs_path)
  if logs:
    stats = make_stats(logs)
    res_string = result_former(stats)
    if args.savefile:
      with open(args.savefile, 'w') as savefile:
        savefile.write(res_string)
    else:
      print(res_string)
  else:
    print("There are no logs")
  
