# file: example/plugins.coffee

app = require("#{__dirname}/../hot")()

plugin = (app, config)->
  # react on app events
  app.on 'start', ->
    console.log app
    console.log 'App started!'

  app.on 'stop', ->
    console.log 'App stopped!'

  # return at least an object with a name property
  return name: 'My awesome plugin'


app
  .use plugin
  .start()
  .stop()