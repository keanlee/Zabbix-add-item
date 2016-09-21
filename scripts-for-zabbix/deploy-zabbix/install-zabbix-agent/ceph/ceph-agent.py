#!/usr/bin/python 

import sys
import socket

def main(argv):

	cmd = "null_cmd"

	for arg in argv:
		if (arg == "status_cmd" ):
			cmd = "status_cmd"
			break
		elif( arg == "osd_pool_stats_cmd" ):
			cmd = "osd_pool_stats_cmd"
			break
		elif( arg == "osd_tree_cmd" ):
			cmd = "osd_tree_cmd"
			break
		elif( arg == "osd_df_cmd" ):
			cmd = "osd_df_cmd"
			break
		elif( arg == "pg_stat_cmd" ):
			cmd = "pg_stat_cmd"
			break
		elif( arg == "osd_perf_cmd" ):
			cmd = "osd_perf_cmd"
			break
		elif( arg == "warn_cmd" ):
			cmd = "warn_cmd"
			break
	else:
		return 0

	s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

	s.connect("/tmp/ceph-monitor-agent-socket")

	s.send(cmd)

	data = s.recv(16384)

	s.close()


	print data

if __name__ == '__main__':
	main(sys.argv)
