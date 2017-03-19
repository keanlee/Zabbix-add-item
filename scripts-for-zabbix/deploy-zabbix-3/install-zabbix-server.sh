#!/bin/sh
#author by haoli on 13th Oct of 2016
#wget -r -p -np -k -P ./ http://110.76.187.145/repos/
echo -e "\e[1;33m Thank for you use this script to deploy zabbix-server, this script can be help you deploy zabbix3 on CentOS 7. This script also can upgrade zabbix 3.0 to 3.2 or downgrade zabbix 3.2 to 3.0 ,you can execute this script again and choose a new version to install when you want upgrade or downgrade, but be note: upgrade and downgrade will be delete all data of before \e[0m"

OSVERSION=$(cat /etc/redhat-release | awk '{print $4}' | awk -F "." '{print $2}')

function install(){
#echo -e " \033[1m Begin install zabbix server  ..."
echo -e "\e[1;32m Begin install zabbix server  ... \e[0m"
#mkdir /etc/yum.repos.d/bak
#mv /etc/yum.repos.d/*  /etc/yum.repos.d/bak/  1>/dev/null 2>&1 
rm -rf /etc/yum.repos.d/* 
echo -e "\e[1;33m Please choose which version of zabbix-server you want to install (Note:you can only choose 3.0 or 3.2 to install. 3.0 is LTS Version ,3.2 is latest version ): \e[0m"

#--------------------this functin is setup the yum repo, you can change the repo on ./repo dir
function choiceversion(){
      case $1 in
       3.2)
       cp ./repo/Cent*  /etc/yum.repos.d/
       cp ./repo/zabbix3.2.repo  /etc/yum.repos.d/
       ;; 
       3.0)
       cp ./repo/Cent*  /etc/yum.repos.d/
       cp ./repo/zabbix3.0.repo   /etc/yum.repos.d/
       esac 
     }
read VERSION
choiceversion $VERSION

echo -e "\e[1;32m setup zabbix repos successfull \e[0m"
#------------------execute the install script --------
source ./modularization/install.sh 
source ./modularization/firewall.sh
echo -e "\e[1;32m ----->Please Go Ahead Zabbix frontend to finished install zabbix server \e[0m"
echo -e "\e[1;32m ----->PLEASE Login as Admin/zabbix in IP/zabbix by your Browser \e[0m"
}

function choice(){
          case $1 in
          1)
          #--------------Downgrade the pacakge of systemc, since the higher version cause can't start zabbix-server daemon
          rpm -Uvh --force ./pacakges/gnutls-3.1.18-8.el7.x86_64.rpm   1>/dev/null 2>&1 
          install
          ;;
          2)
          echo "This script will be deploy zabbix-server on $(cat /etc/redhat-release)"
          install
          ;;
          3)
          echo "This script will be deploy zabbix-server on $(cat /etc/redhat-release)"
          install
          exit 0
          esac
}

if [ $(rpm -qa | grep zabbix | wc -l) -ge 1 ];then
source ./modularization/clean.sh
choice $OSVERSION
else
choice $OSVERSION
fi
