#!/bin/sh
#author by haoli on 24th Jan of 2017

function install(){
echo -e " \033[1m Begin install zabbix agent 3.0.7 ..."
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
#if you don't want disable selinux, you can disable selinux for zabbix only :
#setsebool -P httpd_can_connect_zabbix 1
#setsebool -P zabbix_can_network 1

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config #disable selinux in conf file 
setenforce 0  &&
echo "----->The Selinux Status: $( getenforce)"
#rm -f /etc/yum.repos.d/zabbix*
#yum_zabbix_repo_install &&
rpm -ivh zabbix-agent-3.0.7-1.el7.x86_64.rpm 1>/dev/null 2>&1 &&
#echo "setup zabbix repos successfull"
#yum install zabbix-agent -y   1>/dev/null 2>&1 &&
echo -e "\e[1;32m zabbix-agent installed \e[0m"
#yum install zabbix-sender -y  1>/dev/null 2>&1 &&
rpm -ivh zabbix-sender-3.0.7-1.el7.x86_64.rpm 1>/dev/null 2>&1 &&
echo -e "\e[1;32m zabbix-sender installed \e[0m"
function config(){
sed -i "s/Server=127.0.0.1/Server=$1/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive=127.0.0.1/ServerActive=$1/g"  /etc/zabbix/zabbix_agentd.conf
sed -i "s/Hostname=Zabbix\ server/Hostname=$2/g"  /etc/zabbix/zabbix_agentd.conf
sed -i "167 i HostMetadata=$3"  /etc/zabbix/zabbix_agentd.conf
sed -i "60 i -A INPUT -p tcp -m multiport --ports 10050 -m comment --comment \"zabbix agent \" -j ACCEPT " /etc/sysconfig/iptables
mkdir -p /etc/zabbix/scripts 
chown -R zabbix:zabbix /etc/zabbix/scripts 
}
#read -p  "Please type the zabbix-server ip(for example:192.168.0.1),hostname,hostmetadata: " serverip hostname hostmetdata
#config $serverip $hostname $hostmetdata
echo -e "\e[1;31m Please type the zabbix-server's ip: \e[0m"
read zabbixserverip
echo -e "\e[1;31m Plese type the Hostname(This server ip is also ok) that will be show on the zabbix-server (click Configuration->Hosts on web page) \e[0m:"
read hostname 
echo -e "\e[1;31m Please type the HostMetadata: \e[0m"
read metadata
config $zabbixserverip $hostname $metadata
#echo "Has been finish the zabbix-agent conf file setup"
systemctl restart iptables
systemctl enable zabbix-agent 
systemctl start zabbix-agent &&
echo -e "\e[1;32m Zabbix agent has been install, you can go ahead to the zabbix server to add this server to host list ,thank you use this scrip to install zabbix-agent\e[0m "
}


function clean(){
      echo "Begin clean zabbix agent installed env ..."
      yum erase zabbix-agent zabbix-sender -y
      rm -rf /etc/zabbix
      echo "Finshed clean env "
      }
#zabbixcount="$(rpm -qa | grep zabbix | wc -l)"
if [ $(rpm -qa | grep zabbix | wc -l) -ge 1 ];then
clean
install
else
install
fi
