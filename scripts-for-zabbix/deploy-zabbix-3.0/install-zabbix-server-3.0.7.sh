#!/bin/sh
#author by haoli on 13th Oct of 2016
#wget -r -p -np -k -P ./ http://110.76.187.145/repos/

echo "Hi, Thank for you use this script to deploy zabbix-server, this scrip can be help you deploy zabbix3.0 on 
CentOS7.1/7.2/7.3  "
function install(){
echo -e " \033[1m Begin install zabbix server 3.0 ..."
 #rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm  1>/dev/null 2>&1 &&
yum_zabbixbase_repo_install()
{  

      echo > zabbixbase.repo
      cat > ./zabbixbase.repo << EOF

[base]
name=Yum base 
baseurl=http://110.76.187.3/newton/zabbix3.0.7/base/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX

[extras]
name=Yum extras
baseurl=http://110.76.187.3/newton/zabbix3.0.7/extras/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX

[update]
name=Yum update
baseurl=http://110.76.187.3/newton/zabbix3.0.7/updates/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX
EOF
      mv ./zabbixbase.repo /etc/yum.repos.d/
     
}
 zabbix_version(){
            echo > zabbix3.0.repo
            cat > ./zabbix3.0.repo << EOF
[zabbix]
name=Zabbix Official Repository - zabbix
baseurl=http://110.76.187.3/newton/zabbix3.0.7/zabbix/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX

[zabbix-non-supported]
name=Zabbix Official Repository - non-supported
baseurl=http://110.76.187.3/newton/zabbix-non-supported/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX
EOF
    mv ./zabbix3.0.repo /etc/yum.repos.d/
}
rm -f /etc/yum.repos.d/* &&
echo "Please choose which version of zabbix-server you want to install (Note:you can only choose 3.0 or 3.2 to install. 3.0 is LTS Version 3.2 is latest version ): "
function choiceversion(){
      case $1 in
       3.2)
        yum_zabbixbase_repo_install            
        rpm -ivh http://repo.zabbix.com/zabbix/3.2/rhel/7/x86_64/zabbix-release-3.2-1.el7.noarch.rpm 1>/dev/null 2>&1
       ;; 
       3.0)
        yum_zabbixbase_repo_install 
        zabbix_version
       esac 
     }
#echo "Please choose which version of zabbix-server you want to install (3.0 or 3.2): "  
read version 
choiceversion $version
#yum_zabbix_repo_install &&
echo "setup zabbix repos successfull"



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
echo -e " \033[1m --->All pacakge of zabbix has been installed, Begin to import data to zabbix database ...    "
#import database to mysql 

function choicemysqldata(){
            case $1 in 
            3.2)
            zabbixversion=$(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}')
            zcat   /usr/share/doc/zabbix-server-mysql-$zabbixversion/create.sql.gz | mysql -uzabbix  -pzabbix zabbix  
            ;; 
            3.0)
            zcat   /usr/share/doc/zabbix-server-mysql-3.0.7/create.sql.gz | mysql -uzabbix  -pzabbix zabbix  
           
            esac           
 }
choicemysqldata $version

#zcat   /usr/share/doc/zabbix-server-mysql-3.0.7/create.sql.gz | mysql -uzabbix  -pzabbix zabbix  && 
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


    systemctl enable  httpd 1>/dev/null 2>&1
    systemctl start httpd  &&
echo "----->The httpd daemon is running "
#add zabbix-database size item 
sed -i '294 i  UserParameter=get-zabbix-database-size,/etc/zabbix/scripts/get-zabbix-database-size.sh $1 ' /etc/zabbix/zabbix_agentd.conf &&
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
function iptable(){
           case $1 in
           yes)
iptables -I  INPUT -p tcp --dport 22    -j ACCEPT
iptables -P INPUT DROP
iptables -A  INPUT -p tcp --dport 80    -j ACCEPT
iptables -A  INPUT -p tcp --dport 10050 -j ACCEPT
iptables -A  INPUT -p tcp --dport 10051 -j ACCEPT &&
#firewalld 
#iptables -A IN_public_allow -p tcp -m tcp --dport 10050 -m conntrack --ctstate NEW -j ACCEPT

echo "----->Finshed the firewall,open port:22,80,10050,10051"
             ;;
             no)
             echo "No iptable ruler, you can surf the internet  "
             echo "You has been finished zabbix $(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}') install "
             exit 0
             esac
             echo "You are installed Zabbix-Version: " $(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}')
}
read -p "Do you need configer the firewall ruler (yes/no)? this will course this server can't surf the internet : " num
iptable $num

}

function choice(){
          case $1 in
          1)
          # Downgrade the pacakge of systemc, since the higher version cause can't start zabbix-server daemon
          rpm -Uvh --force http://110.76.187.3/repos/zabbix-2016-09-19/gnutls-3.1.18-8.el7.x86_64.rpm   1>/dev/null 2>&1 
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
       echo "Begin clean installed env..."
       yum erase -y zabbix-server-mysql 1>/dev/null 2>&1
       yum erase -y zabbix-web-mysql 1>/dev/null 2>&1
       yum erase -y mariadb-server 1>/dev/null 2>&1
       yum erase -y zabbix-get  1>/dev/null 2>&1
       yum erase -y zabbix-agent 1>/dev/null 2>&1
       yum erase -y  mariadb-server mariadb mariadb-libs 1>/dev/null 2>&1
       yum erase -y zabbix-release 1>/dev/null 2>&1
       rm -rf /var/lib/mysql
       rm -rf /usr/lib64/mysql
       rm -rf /etc/my.cnf
       rm -f /etc/yum.repos.d/*
       echo "Finshed clean installed env "
}
if [ $(rpm -qa | grep zabbix | wc -l) -ge 1 ];then
clean
choice $num
else
choice $num
fi
