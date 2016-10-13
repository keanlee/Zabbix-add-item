#!/bin/sh
#author by haoli on 13th Oct

# Downgrade the pacakge of systemc, since the higher version cause can't start zabbix-server daemon 
rpm -Uvh --force http://110.76.187.3/repos/zabbix-2016-09-19/gnutls-3.1.18-8.el7.x86_64.rpm &&

rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm

#clean install env 

       yum erase -y zabbix-server-mysql 
       yum erase -y zabbix-web-mysql
       yum erase -y mariadb-server
       yum erase -y zabbix-get 
#install zabbix 3.0 

       yum install zabbix-server-mysql -y 
       yum install zabbix-web-mysql -y
       yum install mariadb-server -y
       yum install zabbix-get -y &&

#start mariadb daemon

systemctl enable mariadb
systemctl start mariadb 

mysqladmin -uroot password admin && 
#crate zabbix user of mysql 
mysql -uroot -padmin -e "create database zabbix character set utf8;grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';flush privileges;" &&
#import database to mysql 
zcat   /usr/share/doc/zabbix-server-mysql-3.0.5/create.sql.gz | mysql -uzabbix  -pzabbix zabbix  && 
echo "----->Import Zabbix Data Success"
#configure the zabbix_server.conf,add the DBPassword=zabbix
sed -i '108 i DBPassword=zabbix' /etc/zabbix/zabbix_server.conf &&

echo "----->/etc/zabbix/zabbix_server.conf edited finished "

#edit the alertpath 
sed -i 's/AlertScriptsPath=\/usr\/lib\/zabbix\/alertscripts/AlertScriptsPath=\/etc\/zabbix\/scripts/' /etc/zabbix/zabbix_server.conf

mkdir -p /etc/zabbix/scripts &&
cp ./Email.py /etc/zabbix/scripts &&
cp ./Wechat.py /etc/zabbix/scripts &&
chown -R zabbix:zabbix /etc/zabbix/scripts &&
echo "----->Email.py and Wechat.py has already copy to /etc/zabbix/scripts"
#configure the timezone of zabbix-web
sed -i '19 i php_value date.timezone Asia/Shanghai ' /etc/httpd/conf.d/zabbix.conf && 

#disable selinux 
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config #disable selinux in conf file 
setenforce 0  &&
echo "----->The Selinux Status: $( getenforce)"

#configure the firewall 
iptables -I  INPUT -p tcp --dport 22    -j ACCEPT
iptables -P INPUT DROP
iptables -A  INPUT -p tcp --dport 80    -j ACCEPT
iptables -A  INPUT -p tcp --dport 10050 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10051 -j ACCEPT &&
echo "----->Finshed the firewall,open port:22,80,10050,10051"

    systemctl enable  httpd &&
    systemctl start httpd  &&
echo "----->The httpd daemon is running "

#start zabbix-agent daemon
    systemctl enable zabbix-agent &&
    systemctl start zabbix-agent &&
echo "----->The zabbix-agent daemon is running "

#start zabbix-server daemon 
systemctl enable zabbix-server &&
systemctl start zabbix-server &&

echo "----->Zabbix Server Daemon Has Been Runing" && 
echo "----->Finshed the firewall,open port:22,80,10050,10051"
echo "----->Please Go Ahead Zabbix frontend to finished install zabbix server"
echo "----->PLEASE Login as Admin/zabbix in IP/zabbix by your Browser" 
