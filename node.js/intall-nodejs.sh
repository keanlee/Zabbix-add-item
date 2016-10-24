#!/bin/bash 
#author by haoli on Oct 24th , 2016
yum install  git  -y 1>/dev/null 2&1 &&
echo "git tools is installed "

git clone https://github.com/keanlee/n.git 
./n/bin/n $1 
cd $(cd $(dirname $0); pwd)
if [ $# = 0 ]; then
  echo "You need to type a version of node.js what you want to install, for example: sh $0 6.2.1 "
if [ $# -gt 1]; then 
  echo "Plese type one version of node.js onece"

