#!/usr/bin/env python
# -*- encoding: utf-8 -*-
#Add new hosts and their items according to the given dict list DL on Zabbix Server.
#Written by Xiaoming in August, 2016!

from ZabbixApiLib import ZabbixAPIException

def CreateZabbixHost(ZA,config,DL={},Entire=False):
    '''DL here is the host list to be added into Zabbix Server!\n
    First, get the existing VM hostname and hostid under groupid (groupname:VM_Group).\n
    Second, add the new host (exist in DL but not in existing hosts).\n
    Third, add each item for the newly added hosts.'''
    RES={'Status':0,'Entire':Entire,'ChangesExist':{},'ChangesCreate':{}}
    Host_Exist_Raw=ZA.host.get(groupids=config.get('group', 'groupid'),output=['host','hostid'])
    Host_Exist_Dict={}
    #get the dict consist of "host:hostid"
    for i in Host_Exist_Raw:
        Host_Exist_Dict[i['host'].encode()]=i['hostid'].encode()
    #Get the list of hosts that exist in DL but not in Zabbix server!
    Host_New_List=list(set(DL.keys()).difference(Host_Exist_Dict.keys()))
    
    #Configure the new VM hosts on Zabbix Server one by one!    
    for host in Host_New_List:
        try:
            status=ZA.host.create(host=host,interfaces=[{"type":config.get('host', 'type'),\
                                                        "main":config.get('host', 'main'),\
                                                        "useip":config.get('host', 'useip'),\
                                                        "ip":config.get('host', 'ip'),\
                                                        "dns":config.get('host', 'dns'),\
                                                        "port":config.get('host', 'port')}],\
                                 templates=[{"templateid":config.get('template','templateid')}],\
                                 groups=[{"groupid":config.get('group','groupid')}])
        except ZabbixAPIException:
            RES['Status']='HostCreateError!'
            return RES
        hostid=status['hostids'][0].encode()
        #Create extra items (vda and nic) that are not included in the template!
        Key_Add_List=list(set(DL[host].keys()).difference(config.options('template_key')))                      
        for k in Key_Add_List:
            if 'mac' in k:
                status=ZA.item.create(hostid=hostid,name=k,key_=k,type=2,value_type=4,delay=60)
            else:
                status=ZA.item.create(hostid=hostid,name=k,key_=k,type=2,value_type=3,delay=60)
        RES['ChangesCreate'][host]=Key_Add_List
    #When Entire=True, check the keys of each VM host existing in both DL and Zabbix server.
    if Entire:
        for host in list(set(DL.keys()).intersection(Host_Exist_Dict.keys())):
            Key_Exist_List=[i['key_'].encode() for i in ZA.item.get(hostids=Host_Exist_Dict[host],output=['key_'])]
            Key_Check_List=list(set(DL[host].keys()).difference(Key_Exist_List))
            for k in Key_Check_List:
                if 'mac' in k:
                    status=ZA.item.create(hostid=Host_Exist_Dict[host],name=k,key_=k,type=2,value_type=4,delay=60)
                else:
                    status=ZA.item.create(hostid=Host_Exist_Dict[host],name=k,key_=k,type=2,value_type=3,delay=60) 
            RES['ChangesExist'][host]=Key_Check_List
    return RES        


#----------------------For Test Use Only Below!--------------------
if __name__ == '__main__':
    from ConfigParser import RawConfigParser
    from ZabbixApiLib import ZabbixAPI
    from VmInitialize import Initialize
    import os
    Path=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    CNF=Path+"/cnf/vmagent.conf"
    config = RawConfigParser()
    config.read(CNF)
    ZA=ZabbixAPI(url=config.get('zabbix','uri'),user=config.get('zabbix', 'user'),password=config.get('zabbix', 'password'))
    

    s=\
{
    "TEST-CreateZabbixHost-TEST": {
        "disk.read.vda_read": 2273, 
        "disk.read.vdb_read": 227353088, 
        "disk.read.vdb_read_req": 15619, 
        "disk.write.vda_write": 130909696, 
        "disk.write.vda_write_req": 18289, 
        "disk.write.vdb_write": 130909696, 
        "disk.write.vdb_write_req": 18289, 
        "net.if.in.eth0": 11651491,
        "net.if.mac.eth0":"FF:FF:FF:FF:FF:FF",
        "net.if.in.eth1": 11651491, 
        "net.if.out.eth0": 17092181, 
        "net.if.out.eth1": 17092181, 
        "status": 0, 
        "system.cpu.util.user": 5, 
        "vm.memory.size.available": 1547496, 
        "vm.memory.size.total": 1
    }
}
    Initialize(ZA,config)
    print CreateZabbixHost(ZA,config,DL=s,Entire=False)
    
    
