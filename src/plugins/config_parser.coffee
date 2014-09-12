# file: plugins/config.coffee

module.exports = (app, opts)->
  plugin =
    name: 'configParser'
    parseArgs: ->
      args = {}
      process.argv.slice(2).map (a)-> args[a.split('=')[0]] = a.split('=')[1]
      return args

  config = plugin.parseArgs()
  # merge with app.config
  for key, value of config
    app.config[key] = value

  return plugin