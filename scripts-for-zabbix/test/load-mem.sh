#!/bin/bash
function load_mem(){
echo -ne "
mkdir /tmp/memory
mount -t tmpfs -o size=$1G tmpfs /tmp/memory
dd if=/dev/zero of=/tmp/memory/block 2>/dev/null
echo  " This will spends $2 seconds to finish the $1G memory load , please be wait !!!"
sleep $2 " | /bin/bash 
}

function clean_env(){
rm /tmp/memory/block
umount /tmp/memory
rm -rf  /tmp/memory
}

echo "Your OS total Mem:" $(free -m | grep -i mem | awk '{print $2 "M"}') 
echo "Please choose how many memory you want to load: __ G"
read memory 
echo "Please type you want to load $memory G memory during how much times  ___ s (seconds)"
read TIME
function choose_backgroud(){
       case $1 in 
       1)
       load_mem $memory $TIME
       #clean_env
      ;;
       2)
       echo "This load memory will be runing backgroud "
      # load_mem $memory $TIME &  1>/dev/null 2>1& 
       
       #echo "if you want end the load memory process , you can kill $! to end  it "  
       esac 
}
echo "Please choose which runinng type you want to execute .Only suport frontend or backgroud (type 1 or 2 ,1 is frontend 2 is backgroud(now is N/A ) ):"
read choice 
choose_backgroud $choice;clean_env


