const http = require('http');
const defaultOutput = require('./defaultOutput');
const parseBody = require('./parseBody');
const writeHead = require('./writeHead');
const getResource = require('./getResource');

module.exports = (config) => {
  const extendResponse = require('./extendResponse')({ endpoint: config.endpoint });
  const db = {};
  // default hooks/middlewares
  const hooks = [
    parseBody,
    extendResponse,
    getResource,
    writeHead
  ];
  const methods = {
    'get': require('./onGet')({ db }),
    // 'post': onPOST,
    // 'patch': onPATCH,
    // 'put': onPUT,
    // 'delete': onDELETE
  };

  const onRequest = require('./onRequest')({ hooks });

  const formats = {
    json: defaultOutput,
    'application/json': defaultOutput
  };

  const server = http.createServer(onRequest);

  // middleware
  // server.use = (fn, opts) => {
  //   plugin = fn @, opts
  //   @plugins[plugin.name] = plugin
  //   @logPluginEvents plugin
  //   @emit 'use', fn, opts
  //   return server;
  // };

  server.start = (done) => server.listen(config.port, done);

  return server;
}
