# file: example/simple_plugin.coffee

module.exports = (app, config)->
  awesome = config.awesome
  # react on app events
  app.on 'start', (next)->
    console.log 'App started!'
    console.log 'With awesomeness!' if awesome

  app.on 'stop', ->
    console.log 'App stopped!'

  # return at least an object with a name property
  return name: 'My awesome plugin'
