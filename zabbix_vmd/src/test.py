from DecoratorLib import TimeLimitbyProcess
from ConfigParser import RawConfigParser
from commands import getoutput
#from NovaDiagnoistics import GetInstancesInfo
import os,time,json,pdb

if __name__=='__main__':
    Path=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    CNF=Path+"/cnf/vmagent.conf"
    config=RawConfigParser()
    config.read(CNF)
    
    @TimeLimitbyProcess(8)
    def test(config=config):
        #res=GetInstancesInfo(config)
        with open('/Users/xiaoming/Documents/workspace/myzabbixagent/src/tmp/new3.txt','r') as f:
            res=eval(f.read())
        print "Sub_Process",len(res),len(repr(res))  
        return res
    
    result=test()
    print "MainProcess: ",type(result)
    print "Main Process",len(result),len(repr(result))