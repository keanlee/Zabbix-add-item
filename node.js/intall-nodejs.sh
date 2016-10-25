#!/bin/bash 
#author by haoli on Oct 24th , 2016
#yum install  git  -y 1>/dev/null 2&1 &&
#echo "git tools is installed "

#git clone https://github.com/keanlee/n.git 
cd $(cd $(dirname $0); pwd)
if [[ $# = 0 ]]; then
  echo "You need to type a version of node.js to tell script which release you want to install, for example: sh $0 6.2.1 "
exit 0
fi
if [[ $# -gt 1 ]]; then 
  echo "Plese type one version of node.js onece"
exit 0
fi
sudo sh nvm.sh $1 
echo "node version:$(node -v)"
echo "npm  version:$(npm -v)"
