var Zabbix = require ('../lib/zabbix');

var zabbix = new Zabbix('http://110.76.187.63/zabbix/api_jsonrpc.php','Admin', 'zabbix');

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
  zabbix.call("host.get",
    {
     "output": "extend",
     
    //"search" : {"host" : ""},
    //"groupids" : "1",
    //"output" : "extend",
    //"sortfield" : "host",
    //"searchWildcardsEnabled" : 1
    }
    ,function (err, resp, body) {
      if (!err) {
        console.log(resp.statusCode + " result: " + JSON.stringify(body.result[0]));
      }
    });
});






