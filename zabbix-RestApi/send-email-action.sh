#! /bin/bash

#curl  -X POST -H "Content-Type: application/json" -d '{"jsonrpc": "2.0", "method":"user.login","params":{"user":"Admin","password":"zabbix"},"id":1}' http://110.76.187.63/zabbix/api_jsonrpc.php >./auth.log  1>/dev/null 2>&1
#auth= $(cat auth.log | awk -F ':' '{print $3}' | awk -F ',' '{print $1}') | sed 's/\"//g'
#echo $auth


curl  -X POST -H "Content-Type: application/json" -d '{

    "jsonrpc": "2.0",
    "method": "action.create",
    "params": {
        "name": "Send E-mail",
        "eventsource": 0,
        "status": 0,
        "esc_period": 120,
        "def_shortdata": "Small-Cluster: {HOST.IP}  {EVENT.TIME} {TRIGGER.STATUS}: {TRIGGER.NAME}",
        "def_longdata": "Trigger: {TRIGGER.NAME}\r\nTrigger status: {TRIGGER.STATUS}\r\nTrigger severity: {TRIGGER.SEVERITY}\r\n\r\nItem values:\r\n\r\n{ITEM.NAME1} ({HOST.NAME1}:{ITEM.KEY1}): {ITEM.VALUE1}\r\n\r\nOriginal event ID: {EVENT.ID}",
        "recovery_msg": 1,
        "r_shortdata": "Small-Cluster: {HOST.IP}  {TRIGGER.STATUS}: {TRIGGER.NAME}" ,
        "r_longdata": "Trigger: {TRIGGER.NAME}\r\nTrigger status: {TRIGGER.STATUS}\r\nTrigger severity: {TRIGGER.SEVERITY}\r\n\r\nItem values:\r\n\r\n{ITEM.NAME1} ({HOST.NAME1}:{ITEM.KEY1}): {ITEM.VALUE1}\r\n\r\nOriginal event ID: {EVENT.ID}",
        "filter": {
            "evaltype": 0,
            "conditions": [
            {
                    "conditiontype": 1,
                    "operator": 0,
                    "value": "10084"
                },
                {
                    "conditiontype": 3,
                    "operator": 2,
                    "value": "memory"
                } 
         ]        
},
        "operations": [
            {
                "operationtype": 0,
                "esc_period": 0,
                "esc_step_from": 1,
                "esc_step_to": 2,
                "evaltype": 0,
                "opmessage_grp": [
                    {
                        "usrgrpid": "7"
                    }
                ],
                "opmessage": {
                    "default_msg": 1,
                    "mediatypeid": "1"
                }
            },
            {
                "operationtype": 1,
                "esc_step_from": 3,
                "esc_step_to": 4,
                "evaltype": 0,
                "opconditions": [
                    {
                        "conditiontype": 14,
                        "operator": 0,
                        "value": "0"
                    }
                ],
                "opcommand_grp": [
                    {
                        "groupid": "2"
                    }
                ],
                "opcommand": {
                    "type": 4,
                    "scriptid": "3"
                }
            }
        ]
    },
    "auth": "175236265af0b7e3a7bdcb0364a9c2de",
    "id": 1
}' http://110.76.187.63/zabbix/api_jsonrpc.php 
