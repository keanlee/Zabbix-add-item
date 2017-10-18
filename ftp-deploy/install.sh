#!/bin/bash
#Author KeanLee
TOP_DIR=$(cd $(dirname $0); pwd)
cd ${TOP_DIR}
FTP_PACKAGE=$(rpm -qa | grep vsftpd | wc -l )
if [[ ${FTP_PACKAGE} -ge 1 ]];then 
    echo $YELLOW  Uninstall the vsftp ...$NO_COLOR
    yum erase vsftpd  -y 1>/dev/null 2>&1  
    rm  -rf  /var/ftp/
    rm  -rf  /etc/vsftpd/
    rm  -rf  /home/ftp/
fi 
# ansi colors for formatting heredoc
ESC=$(printf "\e")
GREEN="$ESC[0;32m"
NO_COLOR="$ESC[0;0m"
RED="$ESC[0;31m"
MAGENTA="$ESC[0;35m"
YELLOW="$ESC[0;33m"
BLUE="$ESC[0;34m"
WHITE="$ESC[0;37m"
#PURPLE="$ESC[0;35m"
CYAN="$ESC[0;36m"

function debug(){
#print exit reason to help debug
if [[ $1 = "warning" ]];then
    echo $YELLOW -----------------------------------------------------\> WARNING $NO_COLOR
    echo $YELLOW WARNING:  $2 $NO_COLOR
elif [[ $1 = 0 ]];then
    echo $GREEN -----------------------------------------------------\>   DONE $NO_COLOR
elif [[ $1 = "notice" ]];then
    echo $CYAN INFO:  $2 $NO_COLOR
else
    echo $RED   -----------------------------------------------------\>  FAILED $NO_COLOR
    echo $RED ERROR:  $2 $NO_COLOR
    exit 1
fi
}


function initialize_env(){
#----------------disable selinux-------------------------
cat 2>&1 <<__EOF__
$MAGENTA==========================================================
            Begin to initialize env ...
==========================================================
$NO_COLOR
__EOF__

if [[ $(cat /etc/selinux/config | sed -n '7p' | awk -F "=" '{print $2}') = "enforcing" ]];then
     echo $BLUE Disable selinux $NO_COLOR
     sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
     echo $GREEN Disable the selinux by config file $NO_COLOR
else
     debug "notice" "The Selinux has been change to disable on the config file on $(hostname)"
fi

if [[ $(getenforce) = "Enforcing" ]];then
    setenforce 0
    echo $GREEN The current selinux Status:$NO_COLOR $YELLOW $(getenforce) $NO_COLOR
fi

#which gzexe && yum erase gzexe -y 1>/dev/null
systemctl status NetworkManager 1>/dev/null 2>&1
if [[ $? = 0 ]];then
    echo $BLUE Uninstall NetworkManager ... $NO_COLOR
    systemctl stop NetworkManager 1>/dev/null 2>&1
    yum erase NetworkManager  -y 1>/dev/null 2>&1
else
    debug "notice" "No NetworkManager Installed on $(hostname)"
fi

which firewall-cmd  1>/dev/null 2>&1 &&
echo $BLUE Uninstall firewalld ...$NO_COLOR
yum erase firewalld* -y 1>/dev/null 2>&1
}

initialize_env
rpm -vih ${TOP_DIR}/vsftp*  1>/dev/null 
systemctl enable vsftpd 1>/dev/null 2>&1  
echo $BLUE Starting the vsftpd daemon $NO_COLOR
systemctl start vsftpd
    debug "$?" "The vsftpd start failed"

sed -i '20 i anon_upload_enable=YES' /etc/vsftpd/vsftpd.conf 
sed -i '20 i anon_mkdir_write_enable=YES' /etc/vsftpd/vsftpd.conf
sed -i '20 i anon_other_write_enable=YES' /etc/vsftpd/vsftpd.conf


mkdir /home/ftp
mkdir  /home/ftp/client1
mkdir  /home/ftp/client2
chmod 777 -R /home/ftp
#sed -i '/^root*/d' /etc/vsftpd/user_list
#sed -i '/^root*/d' /etc/vsftpd/ftpusers
sed -i '20 i ls_recurse_enable=YES'  /etc/vsftpd/vsftpd.conf
sed -i '20 i ascii_upload_enable=YES'  /etc/vsftpd/vsftpd.conf
sed -i '20 i ascii_download_enable=YES' /etc/vsftpd/vsftpd.conf

sed -i '/^anonymous_enable=YES*/d' /etc/vsftpd/vsftpd.conf
sed -i '20 i anonymous_enable=NO' /etc/vsftpd/vsftpd.conf 
useradd ftptest -s /sbin/nologin
passwd ftptest <<EOF
lenovo
lenovo
EOF

#sed -i '20 i local_root=/home/ftp' /etc/vsftpd/vsftpd.conf 
#sed -i '21 i chroot_local_user=YES' /etc/vsftpd/vsftpd.conf 
#sed -i '22 i anon_root=/home/ftp' /etc/vsftpd/vsftpd.conf

chmod 777 -R /var/ftp/pub

echo $BLUE Restarting the vsftpd daemon $NO_COLOR
systemctl restart vsftpd
    debug "$?" "The vsftpd restart failed"
echo $GREEN Finished the FTP deploy $NO_COLOR
