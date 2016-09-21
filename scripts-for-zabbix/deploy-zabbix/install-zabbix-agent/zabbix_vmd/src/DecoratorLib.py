#!/usr/bin/env python
# -*- encoding: utf-8 -*-
from ZabbixApiLib import ZabbixAPI
def ZabbixAPIDeco(config):
    '''Pass the Zabbix object "Z" and configuration object "config" to the decorated function!'''    
    ZA=ZabbixAPI(url=config.get('zabbix','uri'),user=config.get('zabbix', 'user'),password=config.get('zabbix', 'password'))
    def deco1(func):
        def deco2(*args,**kwargs):
            return func(ZA,config,*args,**kwargs)
        return deco2
    return deco1


from multiprocessing import Process,Queue,Event
def TimeLimitbyProcess(timeout):
    '''Block maximum=timeout. Return the result if the child process ends. Otherwise, return None'''
    def decorator(function):
        def decorator2(*args,**kwargs):
            class TimeLimited(Process):
                def __init__(self,result=None,):
                    Process.__init__(self)
                    self.result=result
                    self.queue=Queue()
                    self.event=Event()
                def run(self):
                    self.queue.put(function(*args,**kwargs),block=False)
                    self.event.set()
                def stop(self):
                    if t.is_alive():
                        self.terminate()
            t = TimeLimited()
            t.start()
            t.event.wait(timeout)
            if not t.queue.empty():
                t.result=t.queue.get(block=False)
            t.stop()
            return t.result
        return decorator2
    return decorator
