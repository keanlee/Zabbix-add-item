#!/bin/sh
#author by haoli on 24th Jan of 2017

function install(){
yum_zabbix_repo_install()
{

      echo > zabbix.repo
      cat > ./zabbix.repo << EOF

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
      mv ./zabbix.repo /etc/yum.repos.d/
}
# rm -f /etc/yum.repos.d/* &&
#disable selinux 
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config #disable selinux in conf file 
setenforce 0  &&
echo "----->The Selinux Status: $( getenforce)"
rm -f /etc/yum.repos.d/zabbix*
yum_zabbix_repo_install &&
echo "setup zabbix repos successfull"
yum install zabbix-agent -y   1>/dev/null 2>&1 &&
echo "zabbix-agent installed"
yum install zabbix-sender -y  1>/dev/null 2>&1 &&
echo "zabbix-sender installed "
function config(){
sed -i 's/Server=127.0.0.1/Server=$1/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/ServerActive=127.0.0.1/ServerActive=$2/g'  /etc/zabbix/zabbix_agentd.conf
sed -i 's/Hostname=Zabbix\ server/Hostname=$3/g'  /etc/zabbix/zabbix_agentd.conf
sed -i '167 i HostMetadata=$4' /etc/zabbix/zabbix_agentd.conf
}
read -p  "Please type the zabbix-server ip(for example:192.168.0.1), ServerActive's ip(same as server ip),hostname,hostmetadata: " server-ip server-ip1 
hostname hostmetdata
config $server-ip $server-ip1 $hostname $hostmetdata &&
echo "Has been finish the zabbix-agent conf file setup"
systemctl enable zabbix-agent 
systemctl start zabbix-agent &&
echo "Zabbix agent has been install, you can go ahead to the zabbix server to add this server to host list ,thanks you use this scrip to install zabbix "
}
}

function clean(){
      yum remove zabbix-agent zabbix-sender -y 
      }
#zabbix-count=$(rpm -qa | grep zabbix | wc -l)

function clean(){
      yum remove zabbix-agent zabbix-sender -y
      }
zabbixcount=$(rpm -qa | grep zabbix | wc -l)
if [[ $(zabbixcount) -ge 2 ]]; then
clean
fi
install
