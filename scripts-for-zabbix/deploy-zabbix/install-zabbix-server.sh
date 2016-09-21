#!/bin/bash
#author by haoli on Sep.19, 2016
#configure your system yum repo

#Download the gnutls pacakage 

# Downgrade the pacakge of systemc, since the higher version cause can't start zabbix-server daemon 
rpm -Uvh --force http://110.76.187.3/repos/zabbix-2016-09-19/gnutls-3.1.18-8.el7.x86_64.rpm &&

yum_zabbix_repo_install()
{  

      echo > zabbix.repo
      cat > ./zabbix.repo << EOF
[zabbix]
name=Zabbix Official Repository - $basearch
baseurl=http://110.76.187.3/repos/zabbix-2016-09-19/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX
EOF
      mv ./zabbix.repo /etc/yum.repos.d/
}

 rm -f /etc/yum.repos.d/*
#  yum_base_repo_install
#  yum_epel_repo_install 
  yum_zabbix_repo_install
#clean the system 
    yum clean   all 
    yum erase  -y  zabbix 
    yum erase  -y  zabbix-web
    yum erase  -y  zabbix-agent
    yum erase  -y  mariadb 
    yum erase  -y  mariadb-server
    yum erase  -y  httpd
    yum erase  -y  zabbix-server-mysql
    yum erase  -y  zabbix-get
    yum erase  -y  zabbix-web-mysql
#install zabbix server package
   # set -o xtrace 
    yum install -y zabbix-web-mysql &&
    yum install -y zabbix &&
    yum install -y zabbix-web && 
    yum install -y zabbix-agent &&
    yum install -y mariadb &&
    yum install -y mariadb-server &&
 #   yum install -y httpd && 
    yum install -y zabbix-server zabbix-server-mysql  &&
    yum install -y zabbix-get
   

    systemctl start mariadb && 
    systemctl start httpd  &&
    
echo -e " \033[1m --->All pacakge of zabbix has already installed, Begin to configure the mysql ...    "
  >>/dev/null 

#crate zabbix user of mysql 
mysqladmin -uroot password admin
mysql -uroot -padmin -e "create database zabbix character set utf8;grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';flush privileges;" &&

#import database to mysql 
mysql -uzabbix -pzabbix -e "use zabbix;source /usr/share/doc/zabbix-server-mysql-2.4.8/create/schema.sql;source /usr/share/doc/zabbix-server-mysql-2.4.8/create/images.sql;source /usr/share/doc/zabbix-server-mysql-2.4.8/create/data.sql;"
echo "----->Import Zabbix Data Success"

#show zabbix database talbes 
#echo $(mysql -uzabbix -pzabbix -e "use zabbix;show tables;")

#configure the zabbix_server.conf,add the DBPassword=zabbix 
sed -i '108 i DBPassword=zabbix' /etc/zabbix/zabbix_server.conf

echo "----->/etc/zabbix/zabbix_server.conf edited finished "

#configure the timezone of zabbix-web
sed -i '/\[Date\]/a\date.timezone = Asia/Shanghai' /etc/php.ini 

#Make sure the 10051 prot can be access
#sed -i 's/localhost/127.0.0.1/g' /etc/zabbix/web/zabbix.conf.php

#start zabbix-agent daemon
systemctl start zabbix-agent &&
echo "----->The zabbix-agent daemon is running "

#restart httpd service 
systemctl restart httpd &&
echo "----->httpd daemon is running "

#disable selinux 
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config #disable selinux in conf file 
setenforce 0  &&
echo "----->The Selinux Status: $( getenforce)"

#start zabbix-server daemon 
systemctl start zabbix-server &&
mkdir -p /etc/zabbix/scripts &&
cp ./Email.py /etc/zabbix/scripts &&
cp ./Wechat.py /etc/zabbix/scripts &&
chown -R zabbix:zabbix /etc/zabbix/scripts &&
echo "----->Email.py and Wechat.py has already copy to /etc/zabbix/scripts"
echo "----->Zabbix Server Daemon Has Been Runing"
#configure the firewall 
iptables -I  INPUT -p tcp --dport 22    -j ACCEPT
iptables -P INPUT DROP
iptables -A  INPUT -p tcp --dport 80    -j ACCEPT
iptables -A  INPUT -p tcp --dport 10050 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10051 -j ACCEPT

echo "----->Finshed the firewall,open port:22,80,10050,10051"
echo "----->Please Go Ahead Zabbix frontend to finished install zabbix server"
echo "----->PLEASE Login as Admin/zabbix in IP/zabbix by your Browser"

