
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
    yum remove  -y  zabbix 
    yum remove  -y  zabbix-web
    yum remove  -y  zabbix-agent
    yum remove  -y  mariadb 
    yum remove  -y  mariadb-server
    yum remove  -y  httpd
    yum remove  -y  zabbix-server-mysql
    yum remove  -y  zabbix-get
    yum remove  -y  zabbix-web-mysql
#install zabbix server package
    set -o xtrace 
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
    
echo -e " \033[1m All pacakge of zabbix has already installed  "
  >>/dev/null 
#crate zabbix user of mysql 
mysqladmin -uroot password admin
mysql -uroot -padmin -e "create database zabbix character set utf8;grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';flush privileges;" &&

#import database to mysql 
mysql -uzabbix -pzabbix -e "use zabbix;source /usr/share/doc/zabbix-server-mysql-2.4.8/create/schema.sql;source /usr/share/doc/zabbix-server-mysql-2.4.8/create/images.sql;source /usr/share/doc/zabbix-server-mysql-2.4.8/create/data.sql;"
echo "Import Zabbix Data Success"

#show zabbix database talbes 
echo $(mysql -uzabbix -pzabbix -e "use zabbix;show tables;")

#configure the zabbix_server.conf,add the DBPassword=zabbix 
sed -i '108 i DBPassword=zabbix' /etc/zabbix/zabbix_server.conf

echo "/etc/zabbix/zabbix_server.conf edited finished "

#configure the timezone of zabbix-web
sed -i '/\[Date\]/a\date.timezone = Asia/Shanghai' /etc/php.ini 

#Make sure the 10051 prot can be access
sed -i 's/localhost/127.0.0.1/g' /etc/zabbix/web/zabbix.conf.php

#restart httpd service 
systemctl restart httpd &&
echo "httpd has been restarted "

#disable selinux 
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config #disable selinux in conf file 
setenforce 0  &&
echo $( getenforce)

#start zabbix-server daemon 
systemctl start zabbix-server &&

echo "Zabbix Server Daemon Has Been Runing "
echo "Please Go Ahead Zabbix frontend to finished install zabbix server"



