#!/usr/bin/env python
#coding: utf-8

from ConfigParser import RawConfigParser
from commands import getoutput  # For test only
import re, json, os, datetime, logging, time

from CreateZabbixHost import CreateZabbixHost
from DecoratorLib import TimeLimitbyProcess
from VmInitialize import Initialize, GetMacEthZabbix
from ZabbixApiLib import ZabbixAPI
from ZabbixSendLib import ZabbixMetric, ZabbixSender



from NovaDiagnoistics import GetInstancesInfo
def DataFormatCheck(DataList):
    '''Check: 1. there must be at least one of the following: "cpu0_time",
    "memory-actual","memory-unused","vda_read","vda_read_req","vda_write","vda_write_req";
    2. For every network found, "network_rx", "network_tx", "network_mac" must all exist.'''
    if isinstance(DataList, dict) and len(DataList)>0:
        for item in DataList.keys():
            if not set(["memory-actual","cpu0_time","vda_read","vda_read_req","vda_write","vda_write_req"]).issubset(DataList[item].keys()):
                return -1
        for net in re.findall(r'(?<=\W)[-\w]+(?=_rx(?!_)\W)', repr(DataList[item].keys())):
            if not set([net+"_mac",net+"_tx"]).issubset(DataList[item].keys()):
                return -2
        return 0 #Normal Situation
    return -3 #Input ERROR
        
#Define Logfiel Writing Function
def LogWrite(path,status='',content=''):
    if status != "Started":
        print "LogWrite"
    if not os.path.isdir(path):
        os.makedirs(path)
    t=datetime.datetime.now()
    daytime=t.strftime('%Y-%m-%d')
    daylogfile=path+'/'+'VM'+str(daytime)+'.log'
    logging.basicConfig(filename=daylogfile,level=logging.ERROR,format='%(asctime)s %(message)s ',datefmt='%H:%M:%S %Y-%b-%d')
    logging.error(status+'-> '+content)
    return 0

def DataExtract(DL,VmStatus=0): 
    '''Extract useful data (termed as "TidyDL") from "DL" (short for "DataList")'''
    TidyDL={}
    for host in DL.keys():
        TidyDL[host]={}
        ##get mean value of cpus#
        cpu_times=[]
        for cpu in re.findall(r'(?<=\W)cpu\d+_time',repr(DL[host].keys())):
            cpu_times.append(DL[host][cpu])
            TidyDL[host]["status"]=VmStatus
        TidyDL[host]["system.cpu.util.user"]=sum(cpu_times)/len(cpu_times)
        TidyDL[host]["vm.memory.size.total"]=DL[host]["memory-actual"]
        TidyDL[host]["vm.memory.size.available"]=DL[host]["memory-unused"]if "memory-unused" in DL[host].keys() else 0
        ##get the list of network info _rx and _tx
        Net_List=re.findall(r'(?<=\W)[-\w]+(?=_rx(?!_)\W)',repr(DL[host].keys()))
        Net_List.sort() # sort in plate
        for net in Net_List:
            TidyDL[host][DL[host][net+"_mac"]+"__in"]=DL[host][net+"_rx"]
            TidyDL[host][DL[host][net+"_mac"]+"__out"]=DL[host][net+"_tx"]           
        #get the list of disk IO and request!
        Disk_List=re.findall(r'(?<=\W)vd\w+(?=_read(?!_)\W)',repr(DL[host].keys()))
        Disk_List.sort() # sort in plate   
        for disk in Disk_List:
            TidyDL[host]["disk.read.vd"+chr(ord('a')+Disk_List.index(disk))+"_read"]=DL[host][disk+"_read"]
            TidyDL[host]["disk.write.vd"+chr(ord('a')+Disk_List.index(disk))+"_write"]=DL[host][disk+"_write"]
            TidyDL[host]["disk.read.vd"+chr(ord('a')+Disk_List.index(disk))+"_read_req"]=DL[host][disk+"_read_req"]
            TidyDL[host]["disk.write.vd"+chr(ord('a')+Disk_List.index(disk))+"_write_req"]=DL[host][disk+"_write_req"]
    return TidyDL       

def ZabbixSend(config,DL={},VmStatus=0):
    packet=[]
    if VmStatus:
        for host in DL.keys():
            packet+=[ZabbixMetric(host, "status", VmStatus)]
    else:
        for host in DL.keys():
            packet+=[ZabbixMetric(host, k,v) for k,v in DL[host].items()]
    return ZabbixSender(zabbix_server=config.get('zabbix','address'),zabbix_port=int(config.getint('zabbix','port'))).send(packet)
    
def Differentiate(Old,New,INTERVAL):
    '''For the host in both Old and New: 1) Calculate the value changes; \n\
    2) Check the key name and put it in AddDL if its different.\n\
     For the host in New only: Put it as a whole into AddDL!'''
    DiDL={}
    AddDL={}
    
    if set(Old.keys()).issubset(New.keys()) and set(New.keys()).issubset(Old.keys()):
        Send_List=Old.keys()
    else:
        Send_List=list(set(New.keys()).intersection(Old.keys()))
        #Put the host in New only into AddDL
        for host in list(set(New.keys()).difference(Old.keys())):
            AddDL[host]=New[host]
    #Calculate the value changes per interval for sending.
    for host in Send_List:
            DiDL[host]={}
            for k in list(set(New[host].keys()).intersection(set(Old[host].keys()))):
                if 'mac' in k:
                    DiDL[host][k]=New[host][k] #This net.if.mac.eth_code value for MAC
                elif 'vm.memory.size.total' in k or 'vm.memory.size.available' in k:
                    DiDL[host][k]=int(New[host][k])
                else:
                    DiDL[host][k]=(int(New[host][k])-int(Old[host][k]))/int(INTERVAL) \
                    if int(New[host][k]) >= int(Old[host][k]) else 0
            #Put the new key and its host into AddDL as a dict, if a key appears!  
            Key_New_List=list(set(New[host].keys()).difference(set(Old[host].keys())))   
            if Key_New_List:
                AddDL[host]={}
                for k in Key_New_List:
                    AddDL[host][k]=''            
    return DiDL,AddDL
            
def EthReplace(ZA,config,New,Old={},Initialization=False):
    '''Functionality:: Replace Mac Address using eth_code in keys. "Old" has the eth code already, but New not!\n\
    When Initialization=True, "Old" only include the host with network card (eth[0~9]+) in the form like:\n\
    Old={"host":{"MAC":num,"MAC":num,..},"host2":{"MAC":num,...},...}, where num is an int like:\n\
    "0" in "net.if.net.eth0". (This is the same as the output of MacEth function.)\n\
    Otherwise, Old is directly the data read from CACHE.'''
    
    def MacEth(Old=Old,Initialization=Initialization):
        'Return a dict containing consisting mac:eth_code, like{"FA:16:3E:A4:EA:F8":0,...}.'
        if Initialization:
            return Old
        Mac_Eth_List={}
        for host in Old.keys():
            Eth_Old_List=re.findall(r'(?<=\Wnet\.if\.mac\.eth)\d+(?=\D)',repr(Old[host].keys()))
            if Eth_Old_List:
                Mac_Eth_List[host]={}
                for eth in Eth_Old_List:
                    Mac_Eth_List[host][Old[host]["net.if.mac.eth"+eth]]=int(eth)
        return Mac_Eth_List
    
    def AvailableEth(Exist_Eth_Code,num):
        'Input: a list and an int! Output: first "$num" available codes from "0~max(Exist_Eth_Code)" in ascending order!'
        Exist_Eth_Code.sort()
        Eth_Available_List=list(set(range(len(Exist_Eth_Code)+num)).difference(set(Exist_Eth_Code)))
        Eth_Available_List.sort()   
        return Eth_Available_List
    
    #For the VMs exist in both current data and last data!
    def EthReplaceIntersection(New,Mac_Eth):
        for host in list(set(New.keys()).intersection(Mac_Eth.keys())):
            #Get the eth numbers!
            Mac_New_List=re.findall(r'(?<=\W)(?:\w{2}:){5}\w{2}(?=__in\W)',repr(New[host].keys()))
            Mac_New_List.sort() # sort in plate
            #Existing Macs:
            for mac in list(set(Mac_New_List).intersection(set(Mac_Eth[host].keys()))):
                New[host]["net.if.mac.eth"+str(Mac_Eth[host][mac])]=mac
                New[host]["net.if.in.eth"+str(Mac_Eth[host][mac])]=New[host][mac+"__in"]
                New[host]["net.if.out.eth"+str(Mac_Eth[host][mac])]=New[host][mac+"__out"]
                del New[host][mac+"__in"]
                del New[host][mac+"__out"]
            
            #New Macs: For the mac of an existing host, if it appears in current data but not in last-minute data,
            #the mac may or may not occupy the existing eth code.
            mac_to_align=list(set(Mac_New_List).difference(set(Mac_Eth[host].keys())))
            mac_eth_occupied=list(set(Mac_Eth[host].values()).intersection(mac_to_align))
            eth_available=AvailableEth(mac_eth_occupied,len(mac_to_align)-len(mac_eth_occupied))
            for mac in mac_to_align:
                eth_code=eth_available.pop(0)
                New[host]["net.if.mac.eth"+str(eth_code)]=mac
                New[host]["net.if.in.eth"+str(eth_code)]=New[host][mac+"__in"]
                New[host]["net.if.out.eth"+str(eth_code)]=New[host][mac+"__out"]
                del New[host][mac+"__in"]
                del New[host][mac+"__out"]   
        return New
    EthReplaceIntersection(New=New, Mac_Eth=MacEth())          
    #For new VMs!
    Host_New_list=list(set(New.keys()).difference(Old.keys()))
    if Initialization and Host_New_list:
        for host in Host_New_list:
            Mac_New_List=re.findall(r'(?<=\W)(?:\w{2}:){5}\w{2}(?=__in\W)',repr(New[host].keys()))
            Mac_New_List.sort()
            net_counter=0
            for mac in Mac_New_List:
                New[host]["net.if.mac.eth"+str(net_counter)]=mac
                New[host]["net.if.in.eth"+str(net_counter)]=New[host][mac+"__in"]
                New[host]["net.if.out.eth"+str(net_counter)]=New[host][mac+"__out"]
                del New[host][mac+"__in"]
                del New[host][mac+"__out"] 
                net_counter+=1
    if Initialization==False and len(Host_New_list)>0:
        Host_New_MacEth_Existlist=GetMacEthZabbix(ZA,config,Host_New_list) #Call Zabbix API to get Check if the new hosts have registered on Zabbix already.  
        #For brand new VMs
        for host in list(set(Host_New_list).difference(Host_New_MacEth_Existlist)):
            Mac_New_List=re.findall(r'(?<=\W)(?:\w{2}:){5}\w{2}(?=__in\W)',repr(New[host].keys()))
            Mac_New_List.sort()
            net_counter=0
            for mac in Mac_New_List:
                New[host]["net.if.mac.eth"+str(net_counter)]=mac
                New[host]["net.if.in.eth"+str(net_counter)]=New[host][mac+"__in"]
                New[host]["net.if.out.eth"+str(net_counter)]=New[host][mac+"__out"]
                del New[host][mac+"__in"]
                del New[host][mac+"__out"] 
                net_counter+=1  
        #For new VMs which already exist on Zabbix 
        #Here, set(New).intersection(Host_New_MacEth_Existlist) is the same as\n\
        #set(Host_New_list).intersection(Host_New_MacEth_Existlist)
        EthReplaceIntersection(New=New, Mac_Eth=Host_New_MacEth_Existlist)               
    return New
       

def MainProcess():
    #--------------------------------- Initialization ------------------------------------
    #Prepare Environment Variables:
    #CNF='/Users/xiaoming/Documents/workspace/myzabbixagent/src/vmagent.conf'
    Path=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    CNF=Path+"/cnf/vmagent.conf"
    config=RawConfigParser()
    config.read(CNF)
    INTERVAL=config.getint('vmagent','interval')
    CACHE=Path+"/.cache/vmagent.cache" if not config.has_option('vmagent','cache') else config.get('vmagent','cache')
    LOGPATH=Path+"/log" if not config.has_option('vmagent','logpath') else  config.get('vmagent','logpath')
    ZA=ZabbixAPI(url=config.get('zabbix','uri'),user=config.get('zabbix', 'user'),password=config.get('zabbix', 'password'))
    
    @TimeLimitbyProcess(config.getfloat('vmagent','timeout'))
    def GetInstances(config=config):
        return GetInstancesInfo(config)
    
    #Mark the start to log
    StartStr="VM Daemon starts with PID %d."
    LogWrite(LOGPATH,status="Started",content=StartStr %os.getpid())
    
    
    #One-off execution at start
    VmStatus=1 
    while VmStatus:
        os.system('rm -f '+CACHE)
        Last_Time=int(time.time())    
        try:
            DataList=GetInstances()
	    print "First get info:",DataList
            #Mimic diagnostics API output
            #DataList=eval(getoutput('cat /Users/xiaoming/Documents/workspace/myzabbixagent/src/tmp/new1.txt'))
        except SyntaxError, e:
            LogWrite(LOGPATH,status="SyntaxError on input file", content=repr(e))
        else:
            VmStatus=DataFormatCheck(DataList)
            print "Check result: ",VmStatus
            if VmStatus:
                print "Datacheck Error:",VmStatus
                continue
            if not VmStatus:
                Res_Initialized=Initialize(ZA,config)
                Data_to_Cache=EthReplace(ZA,config,DataExtract(DataList), Old=Res_Initialized["Mac_Eth"],Initialization=True)
                with open(CACHE,'w') as f:
                    f.write(json.dumps(Data_to_Cache))
                CreateZabbixHost(ZA,config,DL=Data_to_Cache,Entire=True)   
        finally:
            Current_Time=int(time.time())
            if Current_Time-Last_Time<INTERVAL:
                print "Initialization: Fall in sleep for {0}/{1}".format(INTERVAL-Current_Time+Last_Time,INTERVAL)
                time.sleep(INTERVAL-Current_Time+Last_Time)
            print "VmMonitoringMain.py >>> Initialization completed!"
    #------------------------------------ Main Iteration ------------------------------------
    interval_count=1    
    while True:
        print "A new iteration starts!------------",time.ctime()
        Last_Time=int(time.time())
        try:
            DataList=GetInstances()
            #Mimic getting the current Data of a list of VMs:s=diagnostics.get_instances_info()
            #DataList=eval(getoutput('cat /Users/xiaoming/Documents/workspace/myzabbixagent/src/tmp/new2.txt'))
        except Exception,e:
            LogWrite(LOGPATH, "VM info Getting ERROR", repr(e))
        else:
            VmStatus=DataFormatCheck(DataList)
            if VmStatus:
                interval_count+=1
                LogWrite(LOGPATH,status="Input Error!",content=repr(DataList))
            else:
                interval_count=1
                NewData=DataExtract(DataList)
                with open(CACHE,'r') as f:
                    OldData=eval(f.read())
                #print "OldData: ",OldData
                NewData=EthReplace(ZA,config,NewData, OldData)
                #print "NewData: ",NewData
                #Save the NewData extracted from DataList for next-round use!
                with open(CACHE,'w') as f:
                    f.write(json.dumps(NewData))
                Send_data,Struct_data=Differentiate(OldData,NewData,interval_count*INTERVAL)
                #print "Send_data",Send_data,"Struct_data",Struct_data
                SendStatus=ZabbixSend(config,Send_data)
                if Struct_data:
                    CreateStatus=CreateZabbixHost(ZA,config,DL=Struct_data, Entire=False)
                    if CreateStatus['Status']:
                        LogWrite(LOGPATH,status="CreateZabbixHost ERROR!", content=CreateStatus['Status'])
                        print "CreateStatus: ",CreateStatus ##for test use only
            
                if SendStatus._failed:
                    LogWrite(LOGPATH,status="SEND FAILED",content=repr(SendStatus))
        Current_Time=int(time.time())
        if Current_Time-Last_Time<INTERVAL:
            print "Fall in sleep for {0}/{1}".format(INTERVAL-Current_Time+Last_Time,INTERVAL)
            time.sleep(INTERVAL-Current_Time+Last_Time)
if __name__ == '__main__': 
    MainProcess()   
    
            
            
        
        
        
     
