#! /bin/bash

# 1.config zabbix repo
# 2.yum install zabbix-agent  zabbix-sender sysstat iptables-services
# 3.mkdir /etc/zabbix/scripts, scp scripts/* /etc/zabbix/scripts owner=zabbix group=owner
# 4.if ceph node, scp ceph/* /etc/zabbix/scripts owner=zabbix group=owner
# 5.config zabbix_agent.conf in openstack or ceph node
# 6.in ceph node config scp services/zabbix-ceph.service /lib/systemd/system/
# 7.in openstack computer nodes scp services/zabbix-vm.service /lib/systemd/system/
# 8.config agent iptables iptables -A INPUT -p tcp -m tcp --dport 10050 -j ACCEPT

cd $(cd `dirname $0`; pwd)

ZABBIX_SERVER=110.76.187.140

usage()
{
    echo "./install_zabbix.sh openstack controller|computer"
    echo "./install_zabbix.sh ceph mon|osd ceph" 
}

log_out()
{
    if [ $1 = 0 ] ;then
        echo "$2 success....................." >> log
    else
        echo "$2 failed please check log....." >> log
        exit 1
    fi
}

yum_zabbix_repo_install()
{

      echo > zabbix.repo
      cat > ./zabbix.repo << EOF
[zabbix]
name=Zabbix Official Repository - $basearch
baseurl=http://110.76.187.3/repos/zabbix-2016-09-19/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX
EOF
      mv ./zabbix.repo /etc/yum.repos.d/
}



zabbix_common()
{
### zabbix common operations, install packages, config common scripts, config iptables
   yum install zabbix-agent  zabbix-sender sysstat iptables-services -y
   log_out "$?" "yum install zabbix-agent  zabbix-sender sysstat iptables-services -y"
   mkdir -p /etc/zabbix/scripts 
   cp scripts/* /etc/zabbix/scripts
   chown -R zabbix.zabbix /etc/zabbix/scripts
   iptables -I INPUT -p tcp -m tcp --dport 10050 -j ACCEPT 
   log_out $? ""
   iptables-save > /etc/sysconfig/iptables
   systemctl enable iptables
   systemctl restart iptables
   log_out "$?" "systemctl restart iptables"
}

zabbix_openstack_config()
{
### config openstack zabbix agent; controller | computer
    cp template/zabbix_openstack_cnf.j2 /etc/zabbix/zabbix_agentd.conf
    sed -i "s/SERVER_IP/$ZABBIX_SERVER/g" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/HOSTNAME/`hostname`/" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/METADATA/$1/" /etc/zabbix/zabbix_agentd.conf
    [ "$1" = "computer" ] && {
    ### config vm monitor
        cp -r zabbix_vmd /etc/zabbix/
        chown zabbix.zabbix /etc/zabbix/zabbix_vmd
        cp services/zabbix-vm.service /lib/systemd/system/ 
        systemctl enable zabbix-vm
        systemctl start zabbix-vm
        log_out "$?" "systemctl start zabbix-vm"
    }
    systemctl restart  zabbix-agent
   log_out "$?" "systemctl restart  zabbix-agent"
}

zabbix_ceph_config()
{
### config ceph zabbix agent; Ceph
    cp template/zabbix_ceph_cnf.j2 /etc/zabbix/zabbix_agentd.conf
    sed -i "s/SERVER_IP/$ZABBIX_SERVER/g" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/HOSTNAME/`hostname`/" /etc/zabbix/zabbix_agentd.conf
    sed -i "s/METADATA/$1/" /etc/zabbix/zabbix_agentd.conf
    [ "$2" = "mon" ] && {
    #### config ceph monitor daemon
        cp services/zabbix-ceph.service /lib/systemd/system/
        systemctl enable zabbix-ceph
        systemctl start zabbix-ceph
    }
    systemctl restart  zabbix-agent
    log_out "$?" "systemctl restart  zabbix-agent"
}

rm -f /etc/yum.repos.d/*
yum_zabbix_repo_install

case $1 in 
openstack)
    zabbix_common
    zabbix_openstack_config $2
    ;;
ceph)
    zabbix_common
    zabbix_ceph_config $2 $3
    ;;
*)
    usage
    ;;
esac
