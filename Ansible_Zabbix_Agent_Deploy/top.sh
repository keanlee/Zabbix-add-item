#!/bin/sh

cat ./tmp.txt
rm -f ./tmp.txt
top -b -n 1 |sed -n '8,9p' | grep -v top | head -n 1 | awk '{if($9>99)print $1; else print 0;}' > tmp.txt &
