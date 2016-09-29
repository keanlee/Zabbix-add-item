#!/usr/bin/env python
# -*- coding: utf-8 -*-
#Functionality: Send Zabbix Alert message via WeChat
#Operation: ./WechatZabbix <WeChat account> <Subject> <Content> for Zabbix 2.4.x
#           ./WechatZabbix <WeChat account> <Content> ...<Content> for Zabbix 3.x.x
#Written by Xiaoming Zheng in July, 2016

import urllib,urllib2,json,argparse,logging,datetime,sys,os
import requests
import urllib3
urllib3.disable_warnings()

reload(sys)
#sys.setdefaultencoding( "utf-8" )


class WeChat(object):
    """Modified by Xiaoming Zheng for zabbix 2.4.8 where the subject and content are combined as the MSG
    First parameter is WechatID, the second one is subject as Email, the third/last one is MSG content!"""
    __token_id = ''
    # init attribute
    def __init__(self,url):
        self.__url = url.rstrip('/')
        self.__corpid = 'wxfc188285b26f1305'
        self.__secret = 'ryNbL7fQdByoDG2694lEvqylRIzjppt0ykd9REDGxioFmDSigvzsvoG0QrdJ9Kbp'
        self.__toparty = '2'
        self.__agentid = '1'

    # Get TokenID
    def authID(self):
        params = {'corpid':self.__corpid, 'corpsecret':self.__secret}
        data = urllib.urlencode(params)
        content = self.getToken(data)
        try:
            self.__token_id = content['access_token']
            #print content['access_token']
        except KeyError:
            raise KeyError
    # Establish a connection
    def getToken(self,data,url_prefix='/'):
        url = self.__url + url_prefix + 'gettoken?'
        try:
            response = urllib2.Request(url + data)
        except KeyError:
            raise KeyError
        result = urllib2.urlopen(response)
        content = json.loads(result.read())
        return content
    # Get sendmessage url
    def postData(self,data,url_prefix='/'):
        url = self.__url + url_prefix + 'message/send?access_token=%s' % self.__token_id
        headers = {'Content-Type': 'application/json', "charset": "utf-8"}
        result = requests.post(url, data=data, headers=headers)
        urllib3.disable_warnings()
        return result

    # send message
    def sendMessage(self,touser,message):
        self.authID()
        data = json.dumps({'touser':touser,
                           #'toparty':self.__toparty,
                           'msgtype':"text",
                           'agentid':self.__agentid,
                           'text':{'content':message},
                           'safe':"0"}, ensure_ascii=False).encode('utf-8')
        response = self.postData(data)
        return response


def take_order(data):
    auth = None
    isLogin = 0
    headers = {"content-type": "application/json"}
    url = "http://life.ctyun.com.cn/admin/ajax/userLogin"
    url1 = "http://life.ctyun.com.cn/ajax/getTodayMeal"
    url2 = "http://life.ctyun.com.cn/ajax/takeOrder"
    data1= {"pageSize":6,"pageNo":1,"query":{}}
    auth = requests.post(url, data=json.dumps(data), headers=headers)
    cookies = auth.cookies
    auth_content = json.loads(auth._content)
    isLogin = auth_content["returnObj"]["isLogin"]
    if isLogin == 0:
        print "%s登录失败" % data["userPhone"]
        message = u"登录失败"
        return message
    meal = requests.post(url1, data=json.dumps(data1), headers=headers, cookies=cookies)
    
    content = json.loads(meal._content)
    result = content["returnObj"]["result"]
    order = None
    flag = 0
    failure_reson = ""
    
    if not result:
        failure_reson = u"没有菜单"
        message = failure_reson
    for r in result:
        if r["mealName"] == u"只限西山赢府":
            data2 = {"id": r["id"]}
            order = requests.post(url2, data=json.dumps(data2), headers=headers, cookies=cookies)
    if order:
        order_content = json.loads(order._content)
        flag = order_content["returnObj"]["isSuccess"]
        failure_reson = order_content["returnObj"]["msg"]
    if flag > 0:
        message = u"订餐成功"
        print message
    else:
        print failure_reson + "(%s)" % data["userPhone"]
        message = failure_reson
    return message


person_list = [
    {"userPhone":"15581639844","userPassword":"123"},
    {"userPhone":"15288844466","userPassword":"1"},
    {"userPhone":"13167592557","userPassword":"123"},
    {"userPhone":"13301166930","userPassword":"123"},
    {"userPhone":"13261399649","userPassword":"123"},
    {"userPhone":"17710236970","userPassword":"123"},
    {"userPhone":"15010612827","userPassword":"123"},
    {"userPhone":"13120923390","userPassword":"123"},
    {"userPhone":"18610218016","userPassword":"1"},
    {"userPhone":"13301246696","userPassword":"123"},
    {"userPhone":"17080138569","userPassword":"123456"},
]
chat_dict = {
    "15581639844": "liuxichao",
    "15288844466": "bijinghao",
    "13167592557": "chenguobin",
    "13301166930": "13301166930",
    "13261399649": "wangwenzhi",
    "15010612827": "bijinghao",
    "13120923390": "xiaomingjeng",
    "18610218016": "lihao",
    "17710236970": "bijinghao",
    "13301246696": "liuxichao",
    "17080138569": "liuyang"
}

for pl in person_list:
    message = take_order(pl)
    if chat_dict.get(pl["userPhone"], None):
        message = message + "(%s)" % chat_dict[pl["userPhone"]]
        a = WeChat('https://qyapi.weixin.qq.com/cgi-bin')
        status=a.sendMessage(chat_dict[pl["userPhone"]],message)
