# file: example/simple_server.coffee

hotcoffee = require("#{__dirname}/../index")()
rss = require "#{__dirname}/rss_format"
plugin = require "#{__dirname}/simple_plugin"

hotcoffee
  .use(plugin, awesome: false) # use simple plugin and set options
  .accept(rss) # add .rss at the end of a resource or pass Accept=application/rss+xml in HTTP header
  .start() # start server
