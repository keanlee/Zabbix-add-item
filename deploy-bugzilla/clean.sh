#!/bib/bash 
#author by lihao
# ansi colors for formatting heredoc
ESC=$(printf "\e")
GREEN="$ESC[0;32m"
NO_COLOR="$ESC[0;0m"
RED="$ESC[0;31m"

echo $RED Begin to clean env........ $NO_COLOR
yum erase -y  mariadb-server mariadb mariadb-libs 1>/dev/null 2>&1
yum erase -y  httpd httpd-tools 1>/dev/null 2>&1
rm -rf /var/lib/mysql
rm -rf /usr/lib64/mysql
rm -rf /etc/my.cnf
rm -f /etc/yum.repos.d/*
yum clean all   1>/dev/null 2>&1
rm -rf /etc/httpd
rm -rf /var/www/html/
echo $GREEN Finished clean Env $NO_COLOR

