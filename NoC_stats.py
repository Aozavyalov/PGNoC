import argparse

def arg_parser_create():
		parser = argparse.ArgumentParser(description="Script for getting statistics of NoC work from generated files.")
		parser.add_argument('logs_file', type=str, help="Path to a logfile.")
		parser.add_argument('-f', '--flit_len', default=38, type=int, help="Length of flit.")
		parser.add_argument('-s', '--savefile', type=str, nargs='?', help="File to save statistics. If not specified, it will print to console.")
		args = parser.parse_args()
		return args

def parse_logs(path_to_logs, flit_len=38):
	# all network stats
	stats = { "flits_sended": 0,
						"flits_recv"	: 0,
						"packs_sended": 0,
						"packs_recved": 0,
						"wrong_flits" : 0,
						"wrong_packs" : 0,
						"mean_time"	 : 0,
						"nodes" : dict(),
						"unknown_flits" : 0
					}
	# dict for saving flit send time and counting mean time
	flits_send_time = dict()
	generated_packs = dict() # generated packets. keys are dest nodes nums, vals are sets with packs
	with open(f"{path_to_logs}", 'r') as logfile:
		for line in logfile:
			splitted = line.split('|')	# splitting log line
			time = int(splitted[0])
			addr = int(splitted[1], base=16)
			mess_type = splitted[2]
			# adding a new node to the stats
			if addr not in stats['nodes']:
				stats['nodes'][addr] = {
					"flits_sended": 0,
					"flits_recv"	: 0,
					"packs_sended": 0,
					"packs_recved": 0,
					"wrong_flits" : 0,
					"wrong_packs" : 0,
					"mean_time"	 : 0,
					"last_flit_send_time" : 0,
					"last_flit_recv_time" : 0,
				}
			if addr not in generated_packs:
				generated_packs[addr] = set()
			if mess_type == "new package":
				pack_len = int(splitted[3].split()[1], base=16)
				dest_addr = int(splitted[4].split()[1], base=16)
				generated_packs[dest_addr].add((splitted[5], pack_len))
			elif mess_type == "package sended":
				stats['nodes'][addr]['packs_sended'] += 1
			elif mess_type == "recved package":
				pack_len = int(splitted[3].split()[1], base=16)
				stats['nodes'][addr]['packs_recved'] += 1
				if (splitted[5], pack_len) in generated_packs[addr]:
					generated_packs[addr].remove((splitted[5], pack_len))
				else:
					stats['nodes'][addr]['wrong_packs'] += 1
			elif mess_type == "flit sended":	# send flit case
				flit = splitted[3][-2::-1]	# reverse for better usability
				stats['nodes'][addr]['flits_sended'] += 1
				flits_send_time[flit] = time
				stats['nodes'][addr]['last_flit_send_time'] = time
			elif mess_type == "recved flit":	# receiving flit case
				flit = splitted[4][-2::-1]	# reverse for better usability
				if flit in flits_send_time:
					stats['nodes'][addr]['flits_recv'] += 1
					stats['nodes'][addr]['mean_time'] += (time - flits_send_time[flit])
					flits_send_time.pop(flit) # removing flit from dict after getting
					stats['nodes'][addr]['last_flit_recv_time'] = time
				else:
					stats['unknown_flits'] += 1
			elif mess_type == "recved wrong flit":
				real_addr = splitted[3].split()[1]
				flit = splitted[4][-2::-1]
				stats['nodes'][addr]['wrong_flits'] += 1
			# else:
			#	 print(f"Unknown message type: {mess_type}")
	# counting mean time for every node after summing
	for node in stats['nodes']:
		if stats['nodes'][node]['flits_recv']: # if any flits recved
			stats['nodes'][node]['mean_time'] = stats['nodes'][node]['mean_time'] / stats['nodes'][node]['flits_recv']
	# all stats
	for node in stats['nodes']:
		stats['flits_sended'] += stats['nodes'][node]['flits_sended']
		stats['flits_recv'] += stats['nodes'][node]['flits_recv']
		stats['packs_sended'] += stats['nodes'][node]['packs_sended']
		stats['packs_recved'] += stats['nodes'][node]['packs_recved']
		stats['wrong_flits'] += stats['nodes'][node]['wrong_flits']
		stats['wrong_packs'] += stats['nodes'][node]['wrong_packs']
		stats['mean_time'] += stats['nodes'][node]['mean_time']  # summing all mean time 
	stats['model_time'] = max([stats['nodes'][node]['last_flit_recv_time'] for node in stats['nodes']])  # modeling time is last time then flit recved
	try:
		stats['mean_time'] = stats['mean_time'] / len(stats['nodes'].keys())  # real mean time calc
	except ZeroDivisionError:  # return None and print values
		print(f"Zero division error:\nFlits sended: {stats['nodes'].keys()}")
		return None
	try:
		stats['fir'] = stats['flits_sended'] / stats['model_time'] / len(stats['nodes'].keys())
	except ZeroDivisionError:  # return None and print values
		print(f"Zero division error:")
		print(f"Flits sended: {stats['flits_sended']}")
		print(f"Model time: {stats['model_time']}")
		print(f"Nodes: {stats['nodes'].keys()}")
		return None
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
	res_str += f"\tWrong packets received: {stats['wrong_packs']}\n"
	res_str += f"\tMean flit receive time: {stats['mean_time']}\n"
	res_str += f"\tUnknown flits num: {stats['unknown_flits']}\n"
	for node in sorted(stats['nodes']):
		res_str += f"{node} node\n"
		res_str += f"\tFlits sended: {stats['nodes'][node]['flits_sended']}\n"
		res_str += f"\tFlits received: {stats['nodes'][node]['flits_recv']}\n"
		res_str += f"\tPackets sended: {stats['nodes'][node]['packs_sended']}\n"
		res_str += f"\tPackets received: {stats['nodes'][node]['packs_recved']}\n"
		res_str += f"\tWrong flits received: {stats['nodes'][node]['wrong_flits']}\n"
		res_str += f"\tWrong packets received: {stats['nodes'][node]['wrong_packs']}\n"
		res_str += f"\tMean flit receive time: {stats['nodes'][node]['mean_time']}\n"
		res_str += f"\tLast flit sended in {stats['nodes'][node]['last_flit_send_time']} time\n"
		res_str += f"\tLast flit received in {stats['nodes'][node]['last_flit_recv_time']} time\n"
	return res_str

if __name__ == "__main__":
	args = arg_parser_create()
	stats = parse_logs(args.logs_file)
	if stats:
		res_string = result_former(stats)
		if args.savefile:
			with open(args.savefile, 'w') as savefile:
				savefile.write(res_string)
		else:
			print(res_string)
