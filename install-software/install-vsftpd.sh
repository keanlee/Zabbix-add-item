#!/bin/bash 
#Author by haoli on Feb. 17th 
function install_config(){
rpm -ivh ./vsftpd-3.0.2-21.el7.x86_64.rpm
systemctl disable firewalld 
iptables -F
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config 
sed -i 's/SELINUXTYPE=targeted/SELINUXTYPE=disabled/g' /etc/selinux/config
#disable selinux in conf file 
setenforce 0  &&
echo "----->The Selinux Status: $( getenforce)"
mkdir /home/ftp
groupadd ftp-users
useradd -g ftp-users -d /home/ftp Unixmen
echo "Please change password for user Unixmen"
passwd Unixmen 
chmod 770 /home/ftp
chown Unixmen:ftp-users /home/ftp
mkdir /home/ftp/Client1
mkdir /home/ftp/Client2
chmod 777 /home/ftp/Client1
chmod 777 /home/ftp/Client2
sed -i '109 i ls_recurse_enable=YES ' /etc/vsftpd/vsftpd.conf
sed -i 's/anonymous_enable=YES/anonymous_enable=NO/g' /etc/vsftpd/vsftpd.conf 
sed -i '84 i ascii_upload_enable=YES ' /etc/vsftpd/vsftpd.conf
sed -i '84 i ascii_download_enable=YES ' /etc/vsftpd/vsftpd.conf
sed -i  '128 i local_root=/home/ftp ' /etc/vsftpd/vsftpd.conf
systemctl enable vsftpd.service
systemctl start vsftpd.service 
echo "Finshed the vsftp service setup "
}

set -x 
install_config 

