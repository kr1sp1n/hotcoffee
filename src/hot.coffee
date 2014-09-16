http = require 'http'
URL = require 'url'
qs = require 'querystring'
fs = require 'fs'
EventEmitter = require('events').EventEmitter

class Hotcoffee extends EventEmitter
  constructor: (config)->
    process.setMaxListeners 0
    @methods = 
      'get': @onGET.bind @
      'post': @onPOST.bind @
      'patch': @onPATCH.bind @
      'delete': @onDELETE.bind @
      'head': @onHEAD.bind @

    @init config

  init: (@config={}, done)->
    @config.port = process.env.PORT or @config?.port or 1337
    @config.host = @config?.host or 'localhost'
    @db = {} # in-memory db
    @plugins = {} # list of plugins
    process.once 'exit', @onExit.bind @
    process.once 'SIGINT', @onSIGINT.bind @
    @emit 'init', @config
    return done(null) if done?

  # plugins
  use: (fn, opts)=>
    plugin = fn @, opts
    @plugins[plugin.name] = plugin
    @emit 'use', fn, opts
    return @

  isRoot: (url)-> url == '/'

  onExit: -> @emit 'exit'

  onSIGINT: ->
    @onExit()
    process.exit(0)

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
      result = (name for name, val of @db)
    else
      if @db[resource]?
        result = @db[resource]
        result = result.filter((x) -> x[key]?) if key? and key.length > 0
        result = result.filter((x) -> String(x[key]) == String(value)) if value?
    @render res, result

  onPOST: (req, res)->
    [ resource, key, value ] = @parseURL req.url
    @db[resource] ?= []
    @parseBody req, (err, body)=>
      if resource != ""
        @db[resource].push body
        @render res, body
        @emit 'POST', resource, body
      else
        @render res, []

  onPATCH: (req, res)->
    [ resource, key, value ] = @parseURL req.url
    @db[resource] ?= []
    result = @db[resource]
    result = result.filter((x) -> x[key]?) if key?
    result = result.filter((x) -> String(x[key]) == String(value)) if value?
    @parseBody req, (err, body)=>
      console.log err if err?
      @merge k, body for k in result
      @emit 'PATCH', resource, result, body
      @render res, result

  onDELETE: (req, res)->
    [ resource, key, value ] = @parseURL req.url
    @db[resource] ?= []
    result = [] # deleted items
    if resource? and not key?
      # delete collection
      result = @db[resource].slice(0) # clone array
      delete @db[resource]
    else
      # delete items
      @db[resource] = @db[resource].filter((x) -> (String(x[key]) != String(value)) or (!result.push x))
    @emit 'DELETE', resource, result
    @render res, result

  onHEAD: (req, res)->
    @emit 'HEAD', req, res
    [ resource, key, value ] = @parseURL req.url
    result = [] # resource keys
    @render res, result

  render: (res, result)->
    res.end JSON.stringify(result, null, 2) + '\n'
    @emit 'render', res, result

  onRequest: (req, res)->
    @emit 'request', req, res
    @writeHead res
    method = req.method.toLowerCase()
    if @methods[method]?
      @methods[method] req, res
    else
      res.end 'Method not supported.\n'

  start: ->
    @emit 'start'
    @server = http.createServer @onRequest.bind @
    @server.listen @config.port
    console.log "HTTP Server listening on port #{@config.port}"
    return @

  stop: ->
    @emit 'stop'
    @server.close()
    return @

module.exports = (config)->
  return new Hotcoffee config

