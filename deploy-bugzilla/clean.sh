#!/bib/bash 
#author by lihao
echo "Begin to clean env........"
yum erase -y  mariadb-server mariadb mariadb-libs 1>/dev/null 2>&1
yum erase -y  httpd httpd-tools 1>/dev/null 2>&1
rm -rf /var/lib/mysql
rm -rf /usr/lib64/mysql
rm -rf /etc/my.cnf
rm -f /etc/yum.repos.d/*
yum clean all   1>/dev/null 2>&1
rm -rf /etc/httpd
rm -rf /var/www/html/
echo "Finished clean Env"

