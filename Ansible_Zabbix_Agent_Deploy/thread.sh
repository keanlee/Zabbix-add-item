#!/bin/bash

if [ 'CpuTotal' = $1 ]
then

  cat ./Ttmp.txt
  #mpstat -P ALL 1 1|grep '^[0-9]'|egrep -v '(CPU)|(all)'|awk 'BEGIN {count=0;}{if(99<$3)count++}END{print count}' > Ttmp.txt &
elif [ 'CpuNumber' = $1 ]
then
  mpstat -P ALL 1 1|grep '^[0-9]'|egrep -v '(CPU)|(all)'|awk 'BEGIN {out=-1;F=1;}{if(99<$3&&F){F=0;out=$2;}}END{print out}'>Ntmp.txt &
  cat ./Ntmp.txt
else
  echo "Only CpuNumber or CpuTotal is acceptable!"
fi
