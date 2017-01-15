#!/bin/sh
#author by haoli on 13th Oct of 2016

function install(){

echo -e " \033[1m Begin install zabbix server 3.0 ..."
# Downgrade the pacakge of systemc, since the higher version cause can't start zabbix-server daemon 
rpm -Uvh --force http://110.76.187.3/repos/zabbix-2016-09-19/gnutls-3.1.18-8.el7.x86_64.rpm   1>/dev/null 2>&1 &&

#rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm  1>/dev/null 2>&1 &&
yum_zabbix_repo_install()
{  

      echo > zabbix.repo
      cat > ./zabbix.repo << EOF

[base]
name=Yum base 
baseurl=http://110.76.187.145/repos/base/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX

[extras]
name=Yum extras
baseurl=http://110.76.187.145/repos/extras/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX

[update]
name=Yum update
baseurl=http://110.76.187.145/repos/updates/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX

[zabbix]
name=Zabbix Official Repository - zabbix
baseurl=http://110.76.187.145/repos/zabbix/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX

[zabbix-non-supported]
name=Zabbix Official Repository - non-supported
baseurl=http://110.76.187.145/repos/zabbix-non-supported/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX

EOF
      mv ./zabbix.repo /etc/yum.repos.d/
}
rm -f /etc/yum.repos.d/* &&
yum_zabbix_repo_install &&
echo "setup zabbix repos successfull"

#clean install env 
#set -x
       yum erase -y zabbix-server-mysql 1>/dev/null 2>&1
       yum erase -y zabbix-web-mysql 1>/dev/null 2>&1
       yum erase -y mariadb-server 1>/dev/null 2>&1
       yum erase -y zabbix-get  1>/dev/null 2>&1
#install zabbix 3.0 

       yum install zabbix-server-mysql -y 1>/dev/null 2>&1 &&
echo "zabbix-server-mysql installed " 
       yum install zabbix-web-mysql -y  1>/dev/null 2>&1  &&
echo "zabbix-web-mysql installed "
       yum install mariadb-server -y  1>/dev/null 2>&1  &&
echo "mariadb-server installed "
       yum install zabbix-agent -y   1>/dev/null 2>&1 &&
echo "zabbix-agent installed "
       yum install zabbix-get -y 1>/dev/null 2>&1 &&
echo "zabbix-get installed "

#start mariadb daemon

systemctl enable mariadb  1>/dev/null 2>&1
systemctl start mariadb 

mysqladmin -uroot password admin && 
#crate zabbix user of mysql 
mysql -uroot -padmin -e "create database zabbix character set utf8;grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';flush privileges;" &&
echo -e " \033[1m --->All pacakge of zabbix has already installed, Begin to import data to zabbix database ...    "

#import database to mysql 
zcat   /usr/share/doc/zabbix-server-mysql-3.0.7/create.sql.gz | mysql -uzabbix  -pzabbix zabbix  && 
echo "----->Import Zabbix Data Success"
#configure the zabbix_server.conf,add the DBPassword=zabbix
sed -i '108 i DBPassword=zabbix' /etc/zabbix/zabbix_server.conf &&

echo "----->/etc/zabbix/zabbix_server.conf edited finished "

#edit the alertpath 
sed -i 's/AlertScriptsPath=\/usr\/lib\/zabbix\/alertscripts/AlertScriptsPath=\/etc\/zabbix\/scripts/' /etc/zabbix/zabbix_server.conf

mkdir -p /etc/zabbix/scripts &&
cp ./Email.py /etc/zabbix/scripts &&
cp ./Wechat.py /etc/zabbix/scripts &&
cp ./get-zabbix-database-size.sh /etc/zabbix/scripts &&
chown -R zabbix:zabbix /etc/zabbix/scripts &&
echo "----->Email.py and Wechat.py has been copy to /etc/zabbix/scripts"
#configure the timezone of zabbix-web
sed -i '19 i php_value date.timezone Asia/Shanghai ' /etc/httpd/conf.d/zabbix.conf && 

#disable selinux 
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config #disable selinux in conf file 
setenforce 0  &&
echo "----->The Selinux Status: $( getenforce)"

#start firewalld
#systemctl start firewalld
#configure the firewall 
iptables -I  INPUT -p tcp --dport 22    -j ACCEPT
iptables -P INPUT DROP
iptables -A  INPUT -p tcp --dport 80    -j ACCEPT
iptables -A  INPUT -p tcp --dport 10050 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10051 -j ACCEPT &&
echo "----->Finshed the firewall,open port:22,80,10050,10051"

    systemctl enable  httpd 1>/dev/null 2>&1
    systemctl start httpd  &&
echo "----->The httpd daemon is running "
#start zabbix-agent daemon
     systemctl enable zabbix-agent 1>/dev/null 2>&1
     systemctl start zabbix-agent &&
     echo "----->The zabbix-agent daemon is running "

#start zabbix-server daemon 
systemctl enable zabbix-server 1>/dev/null 2>&1
systemctl start zabbix-server &&

echo "----->Zabbix Server Daemon Has Been Runing" && 
echo "----->Finshed the firewall,open port:22,80,10050,10051"
echo "----->Please Go Ahead Zabbix frontend to finished install zabbix server"
echo "----->PLEASE Login as Admin/zabbix in IP/zabbix by your Browser" 
}

function choice(){
          case $1 in
          yes)
           install
          ;;
          no)
          echo " Please use CentOS 7.1 to complete zabbix server install " 
          exit 0
          esac
}
read -p  "Pls notice this script is just for CentOS 7.1, your OS is $(cat /etc/redhat-release). Is that correct? (yes/no)?: " num
choice $num
