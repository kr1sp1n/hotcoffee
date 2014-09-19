# file: example/plugins.coffee

app = require("#{__dirname}/../src/hot")()

plugin = (app, config)->
  awesome = config.awesome
  # react on app events
  app.on 'start', (next)->
    console.log 'App started!'
    console.log 'With awesomeness!' if awesome

  app.on 'stop', ->
    console.log 'App stopped!'

  # return at least an object with a name property
  return name: 'My awesome plugin'

app
  .use plugin, { awesome: true }
  .start()
  .stop()