# file: example/simple_server.coffee

hotcoffee = require("#{__dirname}/../index")()
rss = require "#{__dirname}/rss_format"
simple_plugin = require "#{__dirname}/simple_plugin"
hook_plugin = require "#{__dirname}/hook_plugin"

hotcoffee
  .use(simple_plugin, awesome: true) # use simple plugin and set options
  #.use(hook_plugin)
  .accept(rss) # add .rss at the end of a resource or pass Accept=application/rss+xml in HTTP header
  .start() # start server
