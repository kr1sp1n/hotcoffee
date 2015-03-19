http = require 'http'
URL = require 'url'
qs = require 'querystring'
path = require 'path'
EventEmitter = require('events').EventEmitter

class Hotcoffee extends EventEmitter
  constructor: (config)->
    @methods =
      'get': @onGET.bind @
      'post': @onPOST.bind @
      'patch': @onPATCH.bind @
      'delete': @onDELETE.bind @

    # default output formats
    default_output = (res, result)->
      res.end JSON.stringify(result, null, 2) + '\n'
    @formats =
      json: default_output
      'application/json': default_output

    @init config

  init: (@config={}, done)->
    @process = @config.process or process
    @process.setMaxListeners 0
    @config.port = @process.env.PORT or @config?.port or 1337
    @config.host = @config?.host or 'localhost'
    @config.endpoint = @process.env.ENDPOINT or @config?.endpoint or "http://#{@config.host}:#{@config.port}"
    @db = {} # in-memory db
    @server = http.createServer @onRequest.bind @
    @plugins = {} # list of plugins
    @process.once 'exit', @onExit.bind @
    @process.once 'SIGINT', @onSIGINT.bind @
    @emit 'init', @config
    return done(null) if done?

  # plugins
  use: (fn, opts)=>
    plugin = fn @, opts
    @plugins[plugin.name] = plugin
    @emit 'use', fn, opts
    return @

  # content negotiation
  accept: (formats)=>
    # merge with default outputs
    @formats[key] = value for key, value of formats
    return @

  isRoot: (url)-> url == '/'

  onExit: -> @emit 'exit'

  onSIGINT: ->
    @onExit()
    @process.exit(0)

  merge: (dest, source)->
    for key, value of dest
      dest[key] = source[key] if source[key]?
    for key, value of source
      dest[key] = source[key]

  writeHead: (res)->
    res.setHeader 'Access-Control-Allow-Origin', '*'

  parseURL: (url)->
    x = URL.parse(url).pathname.split('/')
    x.shift() # remove first empty string element
    ext = @getExtension url
    if ext?
      [rest..., last] = x
      x[x.length-1] = last.split('.')[0]
    return x

  parseBody: (req, done)->
    body = ''
    req.on 'data', (data)->
      body += data
    req.on 'end', ->
      body = qs.parse body
      # try to parse JSON
      for k, v of body
        try
          body[k] = JSON.parse v
        catch error

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

  extendResponse: (req, res)->
    res.req = req
    res.endpoint = @config.endpoint

  getExtension: (url)->
    x = path.extname(URL.parse(url).pathname).split('.')
    return x[1] if x.length > 1
    return null

  getResource: (url)->
    [resource] = @parseURL url
    return resource

  mapResult: (res, result)->
    if @formats?
      extension = res.req.extension
      accept = res.req.headers['accept']
      format = 'json'
      if @formats[extension]
        format = extension
      else if @formats[accept]
        format = accept
      @formats[format] res, result

  render: (res, result)->
    @mapResult res, result
    @emit 'render', res, result

  onRequest: (req, res)->
    @emit 'request', req, res
    @writeHead res
    @extendResponse req, res
    req.resource = @getResource req.url
    req.extension = @getExtension req.url
    method = req.method.toLowerCase()
    if @methods[method]?
      @methods[method] req, res
    else
      res.end 'Method not supported.\n'

  start: ->
    @server.listen @config.port
    @emit 'start'
    return @

  stop: ->
    @server.close()
    @emit 'stop'
    return @

module.exports = (config)->
  return new Hotcoffee config
