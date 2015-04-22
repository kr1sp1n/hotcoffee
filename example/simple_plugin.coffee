# file: example/simple_plugin.coffee

module.exports = (app, config)->
  awesome = config.awesome
  # react on app events
  app.on 'start', (next)->
    app.log.info 'App started!'
    app.log.info 'With awesomeness!' if awesome

  app.on 'stop', ->
    app.log.info 'App stopped!'

  # return at least an object with a name property
  return name: 'My awesome plugin'
