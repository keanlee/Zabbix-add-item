#!/usr/bin/env python
#coding: utf-8
import socket,os,json
from keystoneauth1 import loading,session
from novaclient import client as nova_client

def GetNovaClient(config,version="2"):
    loader = loading.get_plugin_loader('password')
    auth=loader.load_from_options(
                auth_url=config.get('openstack',"os_auth_url"),
                username=config.get('openstack',"os_username"),
                password=config.get('openstack',"os_password"),
                project_name=config.get('openstack',"os_project_name"),
                user_domain_name=config.get('openstack',"os_user_domain_name"),
                project_domain_name=config.get('openstack',"os_project_domain_name"))
    sess = session.Session(auth=auth)
    return nova_client.Client(version, session=sess)

def GetInstancesInfo(config):
    novaclient = GetNovaClient(config,"2")
    hostname = socket.gethostname()#Get the current local host name

    all_info = {}
    search_opts = {"all_tenants": True, "host": hostname}
    for inst in novaclient.servers.list(search_opts=search_opts):
        if inst.status == 'ACTIVE':
            all_info[inst.id] = inst.diagnostics()[1]
            for port in inst.interface_list():
                all_info[inst.id]["tap" + port.port_id[0:11] + "_mac"] = port.mac_addr.upper()

    return all_info

if __name__=='__main__':
    from ConfigParser import RawConfigParser
    Path=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    CNF=Path+"/cnf/vmagent.conf"
    config=RawConfigParser()
    config.read(CNF)
    res=GetInstancesInfo(config)
    print type(res)
    print json.dumps(res,indent=4,sort_keys=True)
    
