#!/usr/bin/python

import sys
import os
import socket
import rados

socket_path = "/tmp/ceph-monitor-agent-socket"

warn = "0"

def main(argv):
	try:
        	cluster = rados.Rados(conffile='')
	except TypeError as e:
        	print 'Argument validation error: ', e
        	raise e

	print "Created cluster handle."

	try:
        	cluster.connect()
	except Exception as e:
        	print "connection error: ", e
        	raise e
	finally:
        	print "Connected to the cluster."

	s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
	try:
		os.remove( socket_path )
	except OSError:
		pass

	s.bind( socket_path )
        os.chmod(socket_path,766)	
	s.listen(1)
	
	while 1:
	
		conn, addr = s.accept()
		
		cmd = conn.recv(1024)
	
		if not cmd: break

		print cmd

		outbuf = ""
		if ( cmd == "status_cmd" ): 
			cmd = "{\"prefix\": \"status\", \"format\": \"json\"}"
			ret, outbuf, outs = cluster.mon_command(cmd,'')
			conn.send(outbuf)
		elif( cmd == "osd_pool_stats_cmd" ):
			cmd = "{\"prefix\": \"osd pool stats\", \"format\": \"json\"}" 
			ret, outbuf, outs = cluster.mon_command(cmd,'')
			conn.send(outbuf)
		elif ( cmd == "osd_tree_cmd" ):
			cmd = "{\"prefix\": \"osd tree\", \"format\": \"json\"}"
			ret, outbuf, outs = cluster.mon_command(cmd,'')
			conn.send(outbuf)
		elif ( cmd == "osd_df_cmd" ):
			cmd = "{\"prefix\": \"osd df\", \"format\": \"json\"}"
			ret, outbuf, outs = cluster.mon_command(cmd,'')
			conn.send(outbuf)
		elif (cmd == "pg_stat_cmd" ):
			cmd = "{\"prefix\": \"pg stat\", \"format\": \"json\"}"
			ret, outbuf, outs = cluster.mon_command(cmd,'')
			conn.send(outbuf)
		elif (cmd == "osd_perf_cmd" ):
			cmd = "{\"prefix\": \"osd perf\", \"format\": \"json\"}" 
			ret, outbuf, outs = cluster.mon_command(cmd,'')
			conn.send(outbuf)

		if ( outbuf.find("WARN") >= 0 ):
			warn = "1"
		elif ( outbuf.find("ERR") >= 0 ):
			warn = "2"
		else:
			warn = "0"

		if ( cmd == "warn_cmd" ):
			conn.send( warn )
			
		conn.close()

if __name__ == '__main__':
        main(sys.argv)

