# file: index.coffee


# required plugins
configParser = require "#{__dirname}/plugins/configParser"
mongodb = require "#{__dirname}/plugins/mongodb"

hotcoffee = require("#{__dirname}/hot")()

hotcoffee
  .use configParser
  .use mongodb,
    url: 'mongodb://127.0.0.1:27017/hotcoffee'
  .start()