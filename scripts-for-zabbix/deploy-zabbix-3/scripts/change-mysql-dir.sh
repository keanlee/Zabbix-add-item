#!/bin/bash
systemctl stop mariadb &&

#format the disk 
mkfs.ext4 /dev/vdb      #replace by your know partition  e.g. :vda vdb sdb etc  
mount /dev/vdb /home
sed -i '11 i /dev/vdb                /home                   ext4    defaults       0 0  '  /etc/fstab

cp -R /var/lib/mysql/  /home/
chown -R mysql:mysql /home/mysql
#edit my.cnf
sed -i 's/datadir=\/var\/lib\/mysql/datadir=\/home\/mysql' /etc/my.cnf
sed -i 's/socket=\/var\/lib\/mysql\/mysql.sock/socket=\/home\/mysql\/mysql.sock' /etc/my.cnf
systemctl start mariadb &&
ln -s /home/mysql/mysql.sock /var/lib/mysql/mysql.sock
echo "change dir of mysql done "
