#! /bin/bash
# author by lihao on Sep 8th of 2017
echo "Your OS CPU(s) is :"$(lscpu | grep ^CPU\(s\) | awk -F ":" '{print $2}')
endless_loop()
{
echo -ne "i=0;
while true
do
i=i+100;
i=100
done" | /bin/bash &
}

if [ $# != 1 ] ; then
  echo "USAGE: sh $0 cpu's number  "
  exit 1;
fi

for i in `seq $1`
do
  endless_loop
  pid_array[$i]=$! ;
done

echo "You choose load $1 cpu core, if you want to end load cpu, you can use below command:  " 

for pid in "${pid_array[@]}"; do
  
  echo '#'"kill $pid " 
done
