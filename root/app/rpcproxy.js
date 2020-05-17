// RPC Proxy
// Simple Node.js app to whitelist specific RPC functions on a control enabled endpoint
var http = require('http');
var config = require('/config/rpc-proxy.json');

http.createServer((req, res) => {
  var body = '';
  res.setHeader("Access-Control-Allow-Origin", "*");
  req.on('data', function (data) {
    body += data;
    // Only take 1000 bytes should cover all payloads and protect overflows 
    if (body.length > 1000){
      req.connection.destroy();
    }
  });
  // All data recieved from client
  req.on('end', function () {
    try {
      // Parse the payload and check if it's action is in the whitelist
      var payload = JSON.parse(body);
      if ( ! config.whitelist.includes(payload.action)){
        throw ('error');
      }
      // Overide the payload with user defined overrides
      var cleankey = payload.action.replace('_','-');
      if (cleankey in config.overrides){
        var payload = {...payload, ...config.overrides[cleankey]};
      }
      var rpcpayload = JSON.stringify(payload);
      var options = {
        hostname: config.rpchost,
        port: config.rpcport,
        method: 'POST'
      }
      // Send overidden and approved payload to the node RPC
      var rpcreq = http.request(options, rpcres => {
        var rpcbody = '';
        rpcres.on('data', function (rpcdata) {
          rpcbody += rpcdata;
        });
	// Send the user the raw node response
        rpcres.on('end', function () {
          res.write(rpcbody);
          res.end();
        });
      });
      // Our request to the node did not go through
      rpcreq.on('error', error => {
        res.write('{"error":"rpcserver"}');
        res.end();
      })
      rpcreq.write(rpcpayload)
      rpcreq.end()
      // Something went wrong with the payload
    } catch(err) {
      res.write('{"error":"rpcproxy"}');
      res.end();
    }
  });
}).listen(config.port, () => {
    console.log('RPC Proxy is running on port '+ config.port +' to http://' + config.rpchost + ':' + config.rpcport,);
});
