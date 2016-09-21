#!/bin/bash
#written by lenwood
#mail:ccyhaoran@live.cn
 
devlist=$(lsblk -d -n|awk '{print $1}')
 
i=0
for dev in $devlist
do
    let i+=1
done
 
 
k=0
printf "{\n"
printf  '\t'"\"data\":["
 
for dev in $devlist
do
        printf '\n\t\t{'
 
        let k+=1
        if [ $i -eq $k ] ; then
                printf "\"{#DISK_NAME}\":\"${dev}\"}"
        else
                printf "\"{#DISK_NAME}\":\"${dev}\"},"
        fi
 
done
printf  "\n\t]\n"
printf "}\n"
