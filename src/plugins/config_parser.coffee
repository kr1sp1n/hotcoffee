# file: plugins/config.coffee

module.exports = (app, opts)->
  plugin =
    name: 'config_parser'
    parseArgs: ->
      args = {}
      process.argv.slice(2).map (a)-> args[a.split('=')[0]] = a.split('=')[1]
      return args

    init: ->
      config = plugin.parseArgs()
      # merge with app.config
      for key, value of config
        app.config[key] = value

  plugin.init()

  return plugin