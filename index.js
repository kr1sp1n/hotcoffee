const config = require('./config')();
const server = require('./src/server')(config);
server.start();
