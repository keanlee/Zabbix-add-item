#!/bin/bash 
#author by lihao in 2017
ZABBIXSERVER=                                #zabbix server ip 
HOSTNAME=$(hostname)                         #hostname will be display on zabbix server web page 
METADATA=                                    #For Openstack option is controller/compute/ceph/other roles  this will be used for auto Auto registration

function install(){
#-----------------Disable selinux-----------------
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config #disable selinux in conf file 
setenforce 0  &&
echo "----->The Selinux Status: $( getenforce)"

#---------------install package of zabbix agent -----
rpm -ivh ./packages/zabbix-agent-3.0.7-1.el7.x86_64.rpm 1>/dev/null 2>&1 &&
echo -e "\e[1;32m zabbix-agent installed \e[0m"
rpm -ivh ./packages/zabbix-sender-3.0.7-1.el7.x86_64.rpm 1>/dev/null 2>&1 &&
echo -e "\e[1;32m zabbix-sender installed \e[0m"

#--------------configuer the conf file of zabbix agent -----------
sed -i "s/Server=127.0.0.1/Server=$ZABBIXSERVER/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive=127.0.0.1/ServerActive=$ZABBIXSERVER/g"  /etc/zabbix/zabbix_agentd.conf
sed -i "s/Hostname=Zabbix\ server/Hostname=$HOSTNAME/g"  /etc/zabbix/zabbix_agentd.conf
sed -i "167 i HostMetadata=$METADATA"  /etc/zabbix/zabbix_agentd.conf

#--------------iptables setip------
STATUS=$(systemctl status firewalld | grep Active | awk -F ":" '{print $2}' | awk '{print $1}')
if [[ $STATUS = active ]];then
firewall-cmd --zone=public --add-port=10050/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --reload  1>/dev/null 2>&1
elif [ -f /etc/sysconfig/ ];then
iptables -A  INPUT -p tcp --dport 10050 -j ACCEPT
iptables-save > /etc/sysconfig/iptables
else
echo "No iptables rule "
continue
fi

#--------------add item by manual------------------- 
mkdir -p /etc/zabbix/scripts
cp ./script/common/serviceexist.sh /etc/zabbix/scripts/
chown -R zabbix:zabbix /etc/zabbix/scripts
chmod 700 /etc/zabbix/scripts/*

sed -i '294 i  UserParameter=openstack.serviceexist[*],/etc/zabbix/scripts/serviceexist.sh $1 ' /etc/zabbix/zabbix_agentd.conf

#--------------For openstack controller item ---------
if [ $METADATA = controller ];then
cp ./script/controller/check-process-status-openstack.sh  /etc/zabbix/scipt
sed -i '295 i UserParameter=check-process-status-openstack[*],/etc/zabbix/scripts/check-process-status-openstack.sh $1 ' /etc/zabbix/zabbix_agentd.conf
else 
continue 
fi 

#--------------add ceph support -------------------------
if [ $METADATA = ceph ];then
usermod -a -G ceph zabbix
else
continue
fi

systemctl restart iptables  1>/dev/null 2>&1
systemctl enable zabbix-agent 1>/dev/null 2>&1  
systemctl start zabbix-agent &&
echo -e "\e[1;32m Zabbix agent has been install, you can go ahead to the zabbix server to add this server to host list ,thank you use this scrip to install zabbix-agent\e[0m "
}

#--------------------clean agent env ----------
function clean(){
      echo -e "\e[31m Begin clean zabbix agent installed env ...\e[0m "
      yum erase zabbix-agent zabbix-sender -y  1>/dev/null 2>&1
      rm -rf /etc/zabbix
      echo -e "\e[32m Finshed clean env \e[0m"
      }


if [ $(rpm -qa | grep zabbix | wc -l) -ge 1 ];then
clean
install
else
install
fi
