# file: index.coffee


# required plugins
configParser = require "#{__dirname}/plugins/configParser"
mongodb = require "#{__dirname}/plugins/mongodb"

hotcoffee = require("#{__dirname}/hot")()
mongodb_url = process.env['MONGOHQ_URL'] or 'mongodb://127.0.0.1:27017/hotcoffee'
hotcoffee
  .use configParser
  .use mongodb,
    url: mongodb_url
  .start()