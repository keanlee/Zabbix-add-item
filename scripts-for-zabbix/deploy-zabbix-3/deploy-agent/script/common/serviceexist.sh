#!/bin/sh 
#author by lihao on Feb 20th
#this script can be display deamon which is you type if running 
daemon_status=$(systemctl status $1 | grep Active | awk -F ":" '{print $2}' | awk '{print $1}')
if [[ $daemon_status == "inactive" ]]; then
echo "0" #daemon is running 
else
echo "1" #daemon is down
fi
