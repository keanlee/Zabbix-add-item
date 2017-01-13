var Zabbix = require ('../lib/zabbix');

var zabbix = new Zabbix('http://110.76.187.9/zabbix/api_jsonrpc.php','JKZabbix', '2LkGwW/j4uo=');

zabbix.getApiVersion(function (err, res, body) {
  if (!err) {
    console.log("Unauthenticated API version request, and the version is: " + body.result)
  }
});
zabbix.login(function (err, resp, body) {
  if (!err) {
    console.log("Authenticated! AuthID is: " + zabbix.authid);
  }
 // Unless there are any errors, we are now authenticated and can do any call we want to! :)


    zabbix.getApiVersion(function (err, resp, body) {
    console.log("Zabbix API version is: " + body.result);
  });
  zabbix.call("action.create",
    {
   //  "output": "extend",

     
    "name": "Send E-mail",
        "eventsource": 0,
        "status": 0,
        "esc_period": 120,
        "def_shortdata": "Big-Cluster: {HOST.IP}  {EVENT.TIME} {TRIGGER.STATUS}: {TRIGGER.NAME}",
        "def_longdata": "Trigger: {TRIGGER.NAME}\r\nTrigger status: {TRIGGER.STATUS}\r\nTrigger severity: {TRIGGER.SEVERITY}\r\n\r\nItem values:\r\n\r\n{ITEM.NAME1} ({HOST.NAME1}:{ITEM.KEY1}): {ITEM.VALUE1}\r\n\r\nOriginal event ID: {EVENT.ID}",
        "recovery_msg": 1,
        "r_shortdata": "Big-Cluster: {HOST.IP}  {TRIGGER.STATUS}: {TRIGGER.NAME}" ,
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
    }//,

     
    //"search" : {"host" : ""},
    //"groupids" : "1",
    //"output" : "extend",
    //"sortfield" : "host",
    //"searchWildcardsEnabled" : 1
    //}
    ,function (err, resp, body) {
      if (!err) {
        console.log(resp.statusCode + " result: " + JSON.stringify(body.result[0]));
      }
    });
});

