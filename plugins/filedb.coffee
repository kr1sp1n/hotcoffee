# file: plugins/filedb.coffee

class Plugin
  constructor: (@app, @opts)->
    @name = 'filedb'
    @db = {}
    @app.config.file = false
    @app.config.file = @app.config.file if @app.config?.file?
    if @app.config.file
      unless fs.existsSync(@app.config.file)
        console.error "File #{@app.config.file} does not exist."
        process.exit(1)
      try
        @db = require @app.config.file
      catch error
        console.error "File #{@app.config.file} is invalid JSON."
        process.exit(1)

      console.log "with db file #{@app.config.file}" if @app.config.file

  writeDb: -> fs.writeFileSync(@app.config.file, JSON.stringify(@db)) if @app.config.file

module.exports = (app, opts)->
  return new Plugin app, opts