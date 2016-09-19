#!/bin/bash

help()
{
	echo "./fun.sh eth novlan|novlanip|vlan|vlannoip ens3 10.0.38.38"
	echo "./fun.sh yum"
	echo "./fun.sh yum  openstack"
	echo "./fun.sh yum  ceph"
	echo "./fun.sh service computer/control restart/start/stop/status"
}

create_eth()
{
	WORKDIR=/etc/sysconfig/network-scripts

	if [ $# -lt 3 ]; then 
		echo "./fun.sh  eth0  192.168.0.3  255.255.255.0"
		exit 1
	fi

	cfgfile=$WORKDIR/ifcfg-$3
	echo > $cfgfile

	NETMASK=$5

	echo "DEVICE=$3" > $cfgfile
	echo "BOOTPROTO=none" >> $cfgfile
	echo "ONBOOT=yes" >> $cfgfile
        [ "$2" != "novlanip" ] && [ "$2" != "vlannoip" ] && {
	    echo "IPADDR=$4" >> $cfgfile
	    echo "NETMASK=${NETMASK:='255.255.255.0'}" >> $cfgfile
	}
        [ "$2" = "vlan" ] || [ "$2" = "vlannoip" ] && {
            echo "VLAN=yes" >> $cfgfile
        }
	service network restart
}

yum_base_repo_install()
{
	echo > CentOS-Base.repo
	cat > ./CentOS-Base.repo <<EOF
[base]
name=CentOS-7 - Base
baseurl=http://10.0.194.3/repos/centos/base
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates]
name=CentOS-7 - Updates
baseurl=http://10.0.194.3/repos/centos/updates
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-7 - Extras
baseurl=http://10.0.194.3/repos/centos/extras
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
	mv CentOS-Base.repo /etc/yum.repos.d/

}


yum_epel_repo_install()
{
	echo > epel.repo
	cat > epel.repo << EOF
[epel]
name=Extra Packages for Enterprise Linux 7 - x86_64
baseurl=http://10.0.194.3/repos/epel/
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
EOF
	mv epel.repo  /etc/yum.repos.d/
}

yum_openstack_repo_install()
{

	echo > openstack-mitaka.repo
	cat > openstack-mitaka.repo << EOF
[openstack-mitaka]
name=OpenStack Mitaka Repository
baseurl=http://10.0.194.3/repos/openstack-mitaka
skip_if_unavailable=0
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-RDO-kilo
EOF

	mv openstack-mitaka.repo  /etc/yum.repos.d/
}


yum_ceph_repo_install()
{

	echo > ceph-10-2.repo
	cat > ceph-10-2.repo << EOF
[ceph-10.2]
name=ceph Repository
baseurl=http://10.0.194.3/repos/ceph/rpm-jewel/el7/x86_64
skip_if_unavailable=0
enabled=1
gpgcheck=0
EOF

	mv ceph-10-2.repo  /etc/yum.repos.d/
}


log_out()
{
    if [ $1 = 0 ] ;then
        echo "$2 -------------> OK"
    else
        echo "$2 -------------> ERROR"
        exit 1
    fi
}

dvr_control()
{
    systemctl $1 httpd.service memcached.service > /dev/null
    log_out "$?" "systemctl $1 httpd.service memcached.service"

    systemctl $1 openstack-glance-api.service > /dev/null
    log_out "$?" "systemctl $1 openstack-glance-api.service"

    systemctl $1 openstack-glance-registry.service > /dev/null
    log_out "$?" "systemctl $1 openstack-glance-registry.service"

    systemctl $1 openstack-nova-novncproxy.service > /dev/null
    log_out "$?" "systemctl $1 openstack-nova-novncproxy.service"

    systemctl $1 openstack-nova-conductor.service > /dev/null
    log_out "$?" "systemctl $1 openstack-nova-conductor.service"

    systemctl $1 openstack-nova-scheduler.service > /dev/null
    log_out "$?" "systemctl $1 openstack-nova-scheduler.service"

    systemctl $1 openstack-nova-consoleauth.service > /dev/null
    log_out "$?" "systemctl $1 openstack-nova-consoleath.service"

    systemctl $1 openstack-nova-cert.service > /dev/null
    log_out "$?" "systemctl $1 openstack-nova-cert.service"

    systemctl $1 openstack-nova-api.service > /dev/null
    log_out "$?" "systemctl $1 openstack-nova-api.service"

    systemctl $1 neutron-server.service > /dev/null
    log_out "$?" "systemctl $1 neutron-server.service"

    systemctl $1 neutron-openvswitch-agent.service > /dev/null
    log_out "$?" "systemctl $1 neutron-openvswitch-agent.service"

    systemctl $1 neutron-l3-agent.service > /dev/null
    log_out "$?" "systemctl $1 neutron-l3-agent.service"

    systemctl $1 neutron-dhcp-agent.service > /dev/null
    log_out "$?" "systemctl $1 neutron-dhcp-agent.service"

    systemctl $1 neutron-metadata-agent.service > /dev/null
    log_out "$?" "systemctl $1 neutron-metadata-agent.service"

    systemctl $1 openstack-cinder-api.service > /dev/null
    log_out "$?" "systemctl $1 openstack-cinder-api.service"

    systemctl $1 openstack-cinder-scheduler.service > /dev/null
    log_out "$?" "systemctl $1 openstack-cinder-scheduler.service"
}

dvr_computer()
{
    systemctl $1 libvirtd.service > /dev/null
    log_out "$?" "systemctl $1 libvirtd.service"

    systemctl $1 openstack-nova-compute.service > /dev/null
    log_out "$?" "systemctl $1 openstack-nova-compute.service"

    systemctl $1 neutron-openvswitch-agent.service > /dev/null
    log_out "$?" "systemctl $1 neutron-openvswitch-agent.service"

    systemctl $1 neutron-l3-agent.service > /dev/null
    log_out "$?" "systemctl $1 neutron-l3-agent.service"

    systemctl $1 neutron-metadata-agent.service > /dev/null
    log_out "$?" "systemctl $1 neutron-metadata-agent.service"

    systemctl $1 openstack-cinder-volume.service > /dev/null
    log_out "$?" "systemctl $1 openstack-cinder-volume.service"
}

case "$1" in
yum)
	rm -f /etc/yum.repos.d/*
	yum_base_repo_install

	if [ "$2" = "openstack" ]; then
		yum_openstack_repo_install
		yum_ceph_repo_install
		yum_epel_repo_install
	elif [ "$2" = "ceph" ]; then
		yum_ceph_repo_install
		yum_epel_repo_install
	fi

	exit
	;;
eth)
	create_eth $*
	;;

service)
	if [ "$2" = "computer" ]; then
		dvr_computer $3
	elif [ "$2" = "control" ]; then
		dvr_control $3
	else
		echo "the error input"	
	fi
	
	exit
	;;

*)
	help
	;;
esac

