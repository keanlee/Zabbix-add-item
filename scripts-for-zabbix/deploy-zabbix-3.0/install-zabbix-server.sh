#!/bin/sh
#author by haoli on 13th Oct of 2016
#wget -r -p -np -k -P ./ http://110.76.187.145/repos/

echo -e "\e[1;33m Thank for you use this script to deploy zabbix-server, this script 
can be help you deploy zabbix3 on CentOS 7. This script also can upgrade zabbix 3.0 
to 3.2 or downgrade zabbix 3.2 to 3.0 ,you can execute this script again and choose 
a new version to install when you want upgrade or downgrade, but be note: upgrade 
and downgrade will be delete all data of before \e[0m"

function install(){
#echo -e " \033[1m Begin install zabbix server  ..."
echo -e "\e[1;32m Begin install zabbix server  ... \e[0m"
#mkdir /etc/yum.repos.d/bak
#mv /etc/yum.repos.d/*  /etc/yum.repos.d/bak/  1>/dev/null 2>&1 
rm -f /etc/yum.repos.d/* 
echo -e "\e[1;33m Please choose which version of zabbix-server you want to install (Note:you can only choose 3.0 or 3.2 to install. 3.0 is LTS Version ,3.2 is latest version ): \e[0m"
#this functin is setup the yum repo, you can change the repo on ./repo dir
function choiceversion(){
      case $1 in
       3.2)
       cp ./repo/Centos-7.repo    /etc/yum.repos.d/
       cp ./repo/Centos-epel.repo   /etc/yum.repos.d/
       cp ./repo/zabbix3.2.repo  /etc/yum.repos.d/
       ;; 
       3.0)
       cp ./repo/Centos-7.repo  /etc/yum.repos.d/
       cp ./repo/Centos-epel.repo   /etc/yum.repos.d/
       cp ./repo/zabbix3.0.repo   /etc/yum.repos.d/

     # rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm  1>/dev/null 2>&1
       esac 
     }
#echo "Please choose which version of zabbix-server you want to install (3.0 or 3.2): "  
read version 
choiceversion $version
#yum_zabbix_repo_install &&
#echo "setup zabbix repos successfull"
echo -e "\e[1;32m setup zabbix repos successfull \e[0m"
#echo "install zabbix server..." 
       yum clean all 1>/dev/null 2>&1 
       yum install zabbix-server-mysql -y  1>/dev/null 2>&1 &&
#echo "zabbix-server-mysql installed "
echo -e "\e[1;32m zabbix-server-mysql installed \e[0m" 
       yum install zabbix-web-mysql -y     1>/dev/null 2>&1  &&
#echo "zabbix-web-mysql installed "
echo -e "\e[1;32m zabbix-web-mysql installed \e[0m"
       yum install mariadb-server -y    1>/dev/null 2>&1  &&
#echo "mariadb-server installed "
echo -e "\e[1;32m mariadb-server installed \e[0m"
       yum install zabbix-agent -y     1>/dev/null 2>&1 &&
#echo "zabbix-agent installed "
echo -e "\e[1;32m zabbix-agent installed \e[0m"

       yum install zabbix-get -y   1>/dev/null 2>&1 &&
#echo "zabbix-get installed "
echo -e "\e[1;32m zabbix-get installed \e[0m"

#start mariadb daemon

systemctl enable mariadb  1>/dev/null 2>&1
systemctl start mariadb 

mysqladmin -uroot password admin && 
#crate zabbix user of mysql 
mysql -uroot -padmin -e "create database zabbix character set utf8;grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';flush privileges;" &&
echo -e " \e[1;32m --->All pacakge of zabbix has been installed, Begin to import data to zabbix database ...   \e[0m "
#echo -e "\e[1;32m zabbix-sender installed \e[0m"
#import database to mysql 

function choicemysqldata(){
            case $1 in 
            3.2)
            #zabbixversion=
            zcat   /usr/share/doc/zabbix-server-mysql-$(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}')/create.sql.gz | mysql -uzabbix  -pzabbix zabbix  
            ;; 
            3.0)
            zcat   /usr/share/doc/zabbix-server-mysql-$(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}')/create.sql.gz | mysql -uzabbix  -pzabbix zabbix  
           
            esac           
 }
choicemysqldata $version

#zcat   /usr/share/doc/zabbix-server-mysql-3.0.7/create.sql.gz | mysql -uzabbix  -pzabbix zabbix  && 
#echo "----->Import Zabbix Data Success"
echo -e "\e[1;32m ----->Import Zabbix Data Success \e[0m"
#configure the zabbix_server.conf,add the DBPassword=zabbix
sed -i '108 i DBPassword=zabbix' /etc/zabbix/zabbix_server.conf &&

echo -e "\e[1;32m ----->/etc/zabbix/zabbix_server.conf edited finished \e[0m"
#echo -e "\e[1;32m zabbix-sender installed \e[0m"

#edit the alertpath 
sed -i 's/AlertScriptsPath=\/usr\/lib\/zabbix\/alertscripts/AlertScriptsPath=\/etc\/zabbix\/scripts/' /etc/zabbix/zabbix_server.conf

mkdir -p /etc/zabbix/scripts &&
cp ./scripts/Email.py /etc/zabbix/scripts &&
cp ./scripts/Wechat.py /etc/zabbix/scripts &&
cp ./scripts/get-zabbix-database-size.sh /etc/zabbix/scripts &&
cp ./scripts/zabbix.conf.php /etc/zabbix/web  &&
chown -R zabbix:zabbix /etc/zabbix/scripts &&
echo -e "\e[1;32m ----->Email.py and Wechat.py has been copy to /etc/zabbix/scripts \e[0m"
#configure the timezone of zabbix-web
sed -i '19 i php_value date.timezone Asia/Shanghai ' /etc/httpd/conf.d/zabbix.conf && 

#disable selinux 
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config #disable selinux in conf file 
setenforce 0  &&
echo -e "\e[1;32m ----->The Selinux Status: $( getenforce) \e[0m"

#start firewalld
#systemctl start firewalld
#configure the firewall 


    systemctl enable  httpd 1>/dev/null 2>&1
    systemctl start httpd  &&
echo -e "\e[1;32m ----->The httpd daemon is running \e[0m"
#echo -e "\e[1;32m zabbix-sender installed \e[0m"
#add zabbix-database size item 
sed -i '294 i  UserParameter=get-zabbix-database-size,/etc/zabbix/scripts/get-zabbix-database-size.sh $1 ' /etc/zabbix/zabbix_agentd.conf &&
#start zabbix-agent daemon
     systemctl enable zabbix-agent 1>/dev/null 2>&1
     systemctl start zabbix-agent &&
     echo -e "\e[1;32m ----->The zabbix-agent daemon is running \e[0m"
#     echo -e "\e[1;32m zabbix-sender installed \e[0m"

#start zabbix-server daemon 
systemctl enable zabbix-server 1>/dev/null 2>&1
systemctl start zabbix-server &&

echo -e "\e[1;32m ----->Zabbix Server Daemon Has Been Runing \e[0m"  
#echo "----->Finshed the firewall,open port:22,80,10050,10051"
echo -e "\e[1;32m ----->Please Go Ahead Zabbix frontend to finished install zabbix server \e[0m"
echo -e "\e[1;32m ----->PLEASE Login as Admin/zabbix in IP/zabbix by your Browser \e[0m"
#echo -e "\e[1;32m zabbix-sender installed \e[0m" 
function iptable(){
           case $1 in
           yes)
iptables -I  INPUT -p tcp --dport 22    -j ACCEPT
#iptables -P INPUT DROP
iptables -A  INPUT -p tcp --dport 80    -j ACCEPT
iptables -A  INPUT -p tcp --dport 10050 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10051 -j ACCEPT &&
#firewalld 
#iptables -A IN_public_allow -p tcp -m tcp --dport 10050 -m conntrack --ctstate NEW -j ACCEPT

             echo -e "\e[1;32m ----->Finshed the firewall rule setup ,open port:22,80,10050,10051 \e[0m"
             echo -e "\e[1;32m Congratulation !!! You has been finished zabbix $(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}') install \e[0m"
             exit 0
             ;;
             no)
             echo -e "\e[1;33m No firewall rule setup  \e[0m"
             #echo -e "\e[1;32m zabbix-sender installed \e[0m"
             echo -e "\e[1;32m Congratulation !!! You has been finished zabbix $(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}') install \e[0m"
             exit 0
             esac
             #echo " You are installed Zabbix-Version: " $(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}')
}
warning=$(echo -e "\e[1;33m Do you need configer the firewall ruler (yes/no)? default is no : \e[0m")
read -p "$warning" num
iptable $num

}

function choice(){
          case $1 in
          1)
          # Downgrade the pacakge of systemc, since the higher version cause can't start zabbix-server daemon
          rpm -Uvh --force ./pacakges/gnutls-3.1.18-8.el7.x86_64.rpm   1>/dev/null 2>&1 
          install
          ;;
          2)
          echo "This script will be deploy zabbix-server on $(cat /etc/redhat-release)"
          install
          ;;
          3)
          install
          exit 0
          esac
}
num=$(cat /etc/redhat-release | awk '{print $4}' | awk -F "." '{print $2}')
function clean(){
#clean install env 
#set -x
       echo -e "\e[1;31m Your OS current installed zabbix server: $(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}') \e[0m"
       note=$(echo -e "\e[1;31m Do you want delete you current installed zabbix server: $(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}') \e[0m") 
       read -p "$note yes or no: " choice
       function choose(){
       case $1 in 
       yes)
       echo -e "\e[1;31m Begin clean installed env... \e[0m"
       yum erase -y zabbix-server-mysql 1>/dev/null 2>&1
       yum erase -y zabbix-web-mysql 1>/dev/null 2>&1
       yum erase -y mariadb-server 1>/dev/null 2>&1
       yum erase -y zabbix-get  1>/dev/null 2>&1
       yum erase -y zabbix-agent 1>/dev/null 2>&1
       yum erase -y  mariadb-server mariadb mariadb-libs 1>/dev/null 2>&1
       yum erase -y zabbix-release 1>/dev/null 2>&1
       yum erase -y  httpd httpd-tools 1>/dev/null 2>&1
       yum erase -y zabbix-sender 1>/dev/null 2>&1 
       rm -rf /var/lib/mysql
       rm -rf /usr/lib64/mysql
       rm -rf /etc/my.cnf
       rm -f /etc/yum.repos.d/*
       yum clean all   1>/dev/null 2>&1
       rm -rf /etc/httpd
       rm -rf /etc/zabbix/
       echo -e "\e[1;32m Finshed clean installed env \e[0m"
       ;;
       no)
       echo -e "\e[1;34m You are not delete zabbix server \e[0m "
       exit 0
       esac
        }
       choose $choice

}
if [ $(rpm -qa | grep zabbix | wc -l) -ge 1 ];then
clean
choice $num
else
choice $num
fi
