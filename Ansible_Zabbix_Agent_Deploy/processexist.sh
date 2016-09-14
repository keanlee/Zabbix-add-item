#!/bin/sh

let processNumber=0

if [ 1 = $# ]; then
  processNumber=`ps -ef | grep $1 |wc -l`
  processNumber=`expr $processNumber - 3`
elif [ 2 = $# ]; then
  processNumber=`ps -ef | grep $1 | grep $2 |wc -l`
  processNumber=`expr $processNumber - 2`
else
  processNumber=`ps -ef | grep $1 | grep $2 | grep $3 |wc -l`
  processNumber=`expr $processNumber - 2`
fi

if [ $processNumber -gt 0 ]; then
  processNumber=1
fi

echo $processNumber
