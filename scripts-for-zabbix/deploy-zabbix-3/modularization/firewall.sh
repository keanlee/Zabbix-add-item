#!/bin/bash 
#-------------------this script can be help you configuer the firewall rule for zabbix server ------
#author by lihao in March of 2017

function iptabels(){
sed -i "60 i -A INPUT -p tcp -m multiport --ports 22 -m comment --comment \"sshd \" -j ACCEPT " /etc/sysconfig/iptables
#iptables -P INPUT DROP
sed -i "61 i -A INPUT -p tcp -m multiport --ports 10050 -m comment --comment \"zabbix server \" -j ACCEPT " /etc/sysconfig/iptables
sed -i "62 i -A INPUT -p tcp -m multiport --ports 10051 -m comment --comment \"zabbix server \" -j ACCEPT " /etc/sysconfig/iptables
sed -i "63 i -A INPUT -p tcp -m multiport --ports 80 -m comment --comment \"httpd \" -j ACCEPT " /etc/sysconfig/iptables
iptables-save >/etc/sysconfig/iptaables
systemctl restart iptables
}

function firewalld(){
firewall-cmd --zone=public --add-port=80/tcp --permanent  1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=22/tcp --permanent  1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=10050/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --zone=public --add-port=10051/tcp --permanent 1>/dev/null 2>&1
firewall-cmd --reload  1>/dev/null 2>&1
}

if [[ -d /etc/firewalld ]];then
firewalld
elif [ -f /etc/sysconfig/iptaables ];then 
iptabels
else 
continue 
fi
echo -e "\e[1;32m Congratulation !!! You has been finished zabbix $(rpm -qa | grep zabbix-web-mysql | awk -F "-" '{print $4}') install \e[0m"
                        
