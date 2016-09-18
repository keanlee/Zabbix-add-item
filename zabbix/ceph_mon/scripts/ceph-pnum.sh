#!/bin/sh

let processNumber=0

if [ $# = 0 -o $# -gt 1 ]; then
  echo "wrong parameters number, it should be [1~3], \$1 should be service name "
  exit 0
fi

if [ 1 = $# ]; then
    processNumber=`ps -e | grep $1 | grep -v grep | wc -l`
fi

processNumber=`expr $processNumber - 2`

if [ $processNumber -lt 0 ]; then
   processNumber=0
fi

echo $processNumber
