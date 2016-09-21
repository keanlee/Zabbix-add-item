#! /bin/bash

# 1.config zabbix repo
# 2.yum install zabbix-agent  zabbix-sender sysstat iptables-services
# 3.mkdir /etc/zabbix/scripts, scp scripts/* /etc/zabbix/scripts owner=zabbix group=owner
# 4.if ceph node, scp ceph/* /etc/zabbix/scripts owner=zabbix group=owner
# 5.config zabbix_agent.conf in openstack or ceph node
# 6.in ceph node config scp services/zabbix-ceph.service /lib/systemd/system/
# 7.in openstack computer nodes scp services/zabbix-vm.service /lib/systemd/system/
# 8.config agent iptables iptables -A INPUT -p tcp -m tcp --dport 10050 -j ACCEPT

ZABBIX_SERVER=10.0.192.62

usage()
{
    echo "./install_zabbix.sh openstack controller|computer"
    echo "./install_zabbix.sh ceph mon|osd Ceph" 
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


zabbix_common()
{
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
    sed -i "s/SERVER_IP/$ZABBIX_SERVER/g" template/zabbix_openstack_cnf.j2
    sed -i "s/HOSTNAME/`hostname`/" template/zabbix_openstack_cnf.j2
    sed -i "s/METADATA/$1/" template/zabbix_openstack_cnf.j2
    cp template/zabbix_openstack_cnf.j2 /etc/zabbix/zabbix_agentd.conf
    [ "$2" = "computer" ] && {
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
    sed -i "s/SERVER_IP/$ZABBIX_SERVER/g" template/zabbix_ceph_cnf.j2
    sed -i "s/HOSTNAME/`hostname`/" template/zabbix_ceph_cnf.j2
    sed -i "s/METADATA/$1/" template/zabbix_ceph_cnf.j2
    cp template/zabbix_ceph_cnf.j2 /etc/zabbix/zabbix_agentd.conf
    [ "$2" = "mon" ] && {
        cp services/zabbix-ceph.service /lib/systemd/system/
        systemctl enable zabbix-ceph
        systemctl start zabbix-ceph
    }
    systemctl restart  zabbix-agent
    log_out "$?" "systemctl restart  zabbix-agent"
}


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
