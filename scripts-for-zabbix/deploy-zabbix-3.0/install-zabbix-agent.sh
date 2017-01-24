#!/bin/sh
#author by haoli on 24th Jan of 2017


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
rm -f /etc/yum.repos.d/zabbix*
yum_zabbix_repo_install &&
echo "setup zabbix repos successfull"
yum install zabbix-agent -y   1>/dev/null 2>&1 &&
echo "zabbix-agent installed"
yum install zabbix-sender -y  1>/dev/null 2>&1 &&
echo "zabbix-sender installed "
