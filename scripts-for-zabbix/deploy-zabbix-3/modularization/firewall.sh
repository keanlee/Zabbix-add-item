#!/bin/bash 
#-------------------this script can be help you configuer the firewall rule for zabbix server ------
WARNING=$(echo -e "\e[1;33m Do you need configer the firewall ruler (yes/no)? default is no : \e[0m")

function iptable(){
           case $1 in
           yes)
sed -i "60 i -A INPUT -p tcp -m multiport --ports 22 -m comment --comment \"sshd \" -j ACCEPT " /etc/sysconfig/iptables
#iptables -P INPUT DROP
sed -i "61 i -A INPUT -p tcp -m multiport --ports 10050 -m comment --comment \"zabbix server \" -j ACCEPT " /etc/sysconfig/iptables
sed -i "62 i -A INPUT -p tcp -m multiport --ports 10051 -m comment --comment \"zabbix server \" -j ACCEPT " /etc/sysconfig/iptables
sed -i "60 i -A INPUT -p tcp -m multiport --ports 80 -m comment --comment \"httpd \" -j ACCEPT " /etc/sysconfig/iptables
systemctl restart iptables
#vim /etc/sysconfig/iptables
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
read -p "$WARNING" num
iptable $num
