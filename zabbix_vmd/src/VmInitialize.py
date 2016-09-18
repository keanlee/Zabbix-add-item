#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import re
    

def Initialize(ZA,config):
    '''Initialize the hostgroup and template in Zabbix Server printing out the hostgroup id and template id'''    
    def ChkGroupID(groupname=config.get('group','groupname')):
        '''Check group id using group name. Create one when needed!'''
        group_res_raw=ZA.hostgroup.getobjects(name=groupname)
        if not group_res_raw:
            group_res_raw=ZA.hostgroup.create(name=groupname)
            groupid=group_res_raw[u'groupids'][0].encode()
            print "VmInitialize.py >>> Create new host group {0}:{1}".format(groupname,groupid)
        else:
            groupid=group_res_raw[0][u'groupid'].encode()
            print "VmInitialize.py >>> Get the existing groupid of {0}:{1}".format(groupname,groupid)
        return groupid
    
    def ChkTemplateID(groupid,templatename=config.get('template', 'templatename')):
        '''Get template ID from its name, Create a new one and add the items when needed using trapper type!'''
        template_res_raw=ZA.template.getobjects(host=templatename)
        if not template_res_raw:
            template_res_raw=ZA.template.create(host=templatename,groups={"groupid":groupid})
            templateid=template_res_raw[u'templateids'][0].encode()
            for item in config.options('template_key'):
                ZA.item.create(hostid=templateid,name=item,key_=item,type=config.get('template', 'type'),\
                              value_type=config.get('template_key',item),delay=config.get('template', 'delay')) #numeric float
            print "VmInitialize.py >>> Create a new template {0}:{1}".format(templatename,templateid)
        else:
            templateid=template_res_raw[0][u'templateid'].encode()
            print "VmInitialize.py >>> Get the existing templateid of {0}:{1}".format(templatename,templateid)
        return templateid
    
    def GetExistEthCode():
        'Deprecated, use GetMacEthListZabbix(...) instead, please!'
        Mac_Eth={}
        Host_Exist_Raw=ZA.host.get(groupids=config.get('group', 'groupid'),output=['host','hostid'])
        for H in Host_Exist_Raw:
            key_exist_raw=ZA.item.get(hostids=H['hostid'],output=['key_','lastvalue'],search={'key_':'net.if.mac.eth'})
            if key_exist_raw:
                Mac_Eth[H['host'].encode()]={}
                for item in key_exist_raw:
                    Mac_Eth[H['host'].encode()][item[u'lastvalue'].encode()]=int(re.findall(r'(?<=net\.if\.mac\.eth)\d+$',item[u'key_'])[0])            
        return Mac_Eth   
    
    groupid=config.get('group', 'groupid') if config.has_option('group', 'groupid') else ChkGroupID()
    templateid=config.get('template', 'templateid') if config.has_option('template', 'templateid') else ChkTemplateID(groupid)
    #Upgrade configure file if the groupid and templateid are not provided initially, but they are gained now!
    if (groupid and 'groupid' not in config.options('group')) or (templateid  and 'templateid' not in config.options('template')):
        config.set('group','groupid',groupid)
        config.set('template','templateid',templateid)
        #with open(config.CNF,'w') as f:
        #    config.write(f)
    Mac_Eth=GetMacEthListZabbix(ZA,config) #below
    return {"groupid":groupid,"templateid":templateid,"Mac_Eth":Mac_Eth}

#Return a Dict containing the mac:eth_code for Host_New_List
def GetMacEthListZabbix(ZA,config,Host_List=[]):
    'When Host_List=[], it returns all the mac:eth_code for all host'
    Mac_Eth={}
    Host_Exist_Raw=ZA.host.get(groupids=config.get('group', 'groupid'),output=['host','hostid'])
    Host_ID_Exist_DL={i[u'host'].encode():i[u'hostid'].encode() for i in Host_Exist_Raw}    
    for H in (list(set(Host_ID_Exist_DL.keys()).intersection(Host_List)) if Host_List else Host_ID_Exist_DL.keys()):
        key_exist_raw=ZA.item.get(hostids=Host_ID_Exist_DL[H],output=['key_','lastvalue'],search={'key_':'net.if.mac.eth'})
        if key_exist_raw and re.search(r'(?<=\W)(?:\w\w:){5}\w\w(?=\W)', repr(key_exist_raw)):
            Mac_Eth[H]={}
            for item in key_exist_raw:
                if re.match(r'(?:\w\w:){5}\w\w', item[u'lastvalue']):
                    Mac_Eth[H][item[u'lastvalue'].encode()]=int(re.findall(r'(?<=net\.if\.mac\.eth)\d+$',item[u'key_'])[0])            
    return Mac_Eth

def GetMacEthZabbix(ZA,config,Host_List=[]):
    'Z and config are passed by the decorator already!'
    return GetMacEthListZabbix(ZA,config,Host_List=[])
    
#-------------For Test Use Only-----------    
if __name__ == '__main__':
    from ConfigParser import RawConfigParser
    from ZabbixApiLib import ZabbixAPI
    import json,os
    Path=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    CNF=Path+"/cnf/vmagent.conf"
    config=RawConfigParser()
    config.read(CNF)
    
    ZA=ZabbixAPI(url=config.get('zabbix','uri'),user=config.get('zabbix', 'user'),password=config.get('zabbix', 'password'))
    
    print json.dumps(Initialize(ZA,config),indent=4,sort_keys=True)
    #print ConfigDeco(CNF)(GetMacEthListZabbix)() #for call
    print GetMacEthZabbix(ZA,config,Host_List=[])
