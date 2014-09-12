# file: index.coffee

# required plugins
config_parser = require "#{__dirname}/src/plugins/config_parser"
mongo_db = require "#{__dirname}/src/plugins/mongo_db"

hotcoffee = require("#{__dirname}/src/hot")()
mongodb_url = process.env['MONGOHQ_URL'] or 'mongodb://127.0.0.1:27017/hotcoffee'
hotcoffee
  .use(config_parser)
  .use(mongo_db, url: mongodb_url)
  .start()