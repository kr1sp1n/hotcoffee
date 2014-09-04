http = require 'http'
URL = require 'url'
qs = require 'querystring'
fs = require 'fs'
EventEmitter = require('events').EventEmitter

class Hotcoffee extends EventEmitter
  constructor: (@config)->
    unless @config?
      @config = @parseArgs()
    @port = process.env.PORT or @config.port or 1337
    @host = @config.host or 'localhost'
    @file = false
    @file = @config.file if @config?.file?
    @db = {}
    @plugins = {}
    process.on 'exit', =>
      @onExit()
    process.on 'SIGINT', =>
      @onExit()
      process.exit(0)
    if @file
      unless fs.existsSync(@file)
        console.error "File #{@file} does not exist."
        process.exit(1)
      try
        @db = require @file
      catch error
        console.error "File #{@file} is invalid JSON."
        process.exit(1)

  # plugins
  use: (fn, opts)=>
    @emit 'use', fn, opts
    plugin = fn @, opts
    @plugins[plugin.name] = plugin
    return @

  parseArgs: ->
    args = {}
    process.argv.slice(2).map (a)-> args[a.split('=')[0]] = a.split('=')[1]
    return args

  isRoot: (url)-> url == '/'

  onExit: ->
    @emit 'exit'
    @writeDb()

  writeDb: -> fs.writeFileSync(@file, JSON.stringify(@db)) if @file

  merge: (dest, source)->
    for key, value of dest
      dest[key] = source[key] if source[key]?
    for key, value of source
      dest[key] = source[key]

  writeHead: (res)-> 
    res.writeHead 200,
      'Content-Type': 'application/json'
      'Access-Control-Allow-Origin': '*'

  parseURL: (url)->
    x = URL.parse(url).pathname.split('/')
    x.shift() # remove first empty string element
    return x

  parseBody: (req, done)->
    body = ''
    req.on 'data', (data)->
      body += data
    req.on 'end', ->
      body = qs.parse body
      done null, body

  onGET: (req, res)->
    @emit 'GET', req, res
    [ resource, key, value ] = @parseURL req.url
    result = []
    if @isRoot req.url
      result = for name, val of @db
        name
    else
      if @db[resource]?
        result = @db[resource]
        result = result.filter((x) -> x[key]?) if key? and key.length > 0
        result = result.filter((x) -> x[key] == value) if value?
    @render res, result

  onPOST: (req, res)->
    @emit 'POST', req, res
    [ resource, key, value ] = @parseURL req.url
    @db[resource] ?= []
    @parseBody req, (err, body)=>
      console.log err if err?
      @db[resource].push body if resource != ""
      @render res, body

  onPATCH: (req, res)->
    @emit 'PATCH', req, res
    [ resource, key, value ] = @parseURL req.url
    @db[resource] ?= []
    result = @db[resource]
    result = result.filter((x) -> x[key]?) if key?
    result = result.filter((x) -> x[key] == value) if value?
    @parseBody req, (err, body)->
      console.log err if err?
      @merge k, body for k in result
      @render res, result

  onDELETE: (req, res)->
    @emit 'DELETE', req, res
    [ resource, key, value ] = @parseURL req.url
    @db[resource] ?= []
    result = [] # deleted items
    if resource? and not key?
      # delete collection
      result = @db[resource].slice(0) # clone array
      delete @db[resource]
    else
      # delete items
      @db[resource] = @db[resource].filter((x) -> (x[key] != value) or (!result.push x))
    @render res, result

  onHEAD: (req, res)->
    @emit 'HEAD', req, res
    [ resource, key, value ] = @parseURL req.url
    result = [] # resource keys
    @render res, result

  render: (res, result)->
    @emit 'render', res, result
    res.end JSON.stringify(result, null, 2) + '\n'

  onRequest: (req, res)->
    @emit 'request', req, res
    @writeHead res
    method = req.method.toUpperCase()

    switch method
      when "GET" then @onGET req, res
      when "POST" then @onPOST req, res
      when "PUT" then console.log "PUT"
      when "PATCH" then @onPATCH req, res
      when "DELETE" then @onDELETE req, res
      when "HEAD" then @onHEAD req, res
      else
        res.end 'Hello World\n'

  start: ->
    @emit 'start'
    @server = http.createServer @onRequest.bind @
    @server.listen @port
    console.log "HTTP Server listening on port #{@port}"
    console.log "with db file #{@file}" if @file
    return @

  stop: ->
    @emit 'stop'
    @server.close()
    return @

module.exports = (config)->
  return new Hotcoffee config

unless module.parent?
  s = new Hotcoffee()
  s.start()
