http = require 'http'
URL = require 'url'
qs = require 'querystring'
path = require 'path'
bunyan = require 'bunyan'
EventEmitter = require('events').EventEmitter

class Hotcoffee extends EventEmitter
  constructor: (config)->
    @methods =
      'get': @onGET.bind @
      'post': @onPOST.bind @
      'patch': @onPATCH.bind @
      'put': @onPUT.bind @
      'delete': @onDELETE.bind @

    # default hooks
    @hooks = [@parseBody]

    # default output formats
    default_output = (res, result)->
      output = {
        items: result
        href: res.endpoint+res.req.url
      }
      res.setHeader 'Content-Type', 'application/json'
      str = JSON.stringify(output, null, 2) + '\n'
      res.end str
    @formats =
      json: default_output
      'application/json': default_output

    @init config

  init: (@config={}, done)->
    @log = @config.log || bunyan.createLogger name: 'hotcoffee'
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
    @on 'error', (err)=>
      @log.error err.message
    @emit 'init', @config
    return done(null) if done?

  # plugins
  use: (fn, opts)=>
    plugin = fn @, opts
    @plugins[plugin.name] = plugin
    @logPluginEvents plugin
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
    for key, value of dest.props
      dest.props[key] = source[key] if source[key]?
    for key, value of source
      dest.props[key] = source[key]

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

  filterResult: (result, filterBy)->
    {resource, key, value} = filterBy
    result = result.filter((x) -> x.props[key]?) if key? and key.length > 0
    result = result.filter((x) -> String(x.props[key]) == decodeURIComponent(String(value))) if value?
    return result

  parseBody: (req, res, next)->
    body = ''
    req.on 'data', (data)->
      body += data
    req.on 'end', ->
      body = qs.parse body
      for k, v of body
        try
          body[k] = JSON.parse v
        catch error
      req.body = body
      next null, body

  onGET: (req, res)->
    @emit 'GET', req, res
    [ resource, key, value ] = @parseURL req.url
    result = []
    if @isRoot req.url
      result = ({ type:'resource', href:[res.endpoint, name].join('/'), props: { name: name } } for name of @db)
    else
      if @db[resource]?
        result = @filterResult @db[resource], { resource: resource, key: key, value: value}
    @render res, result

  onPOST: (req, res)->
    [ resource, key, value ] = @parseURL req.url
    @db[resource] ?= []
    req.links ?= []
    if resource != ""
      item = { type: resource, props: req.body, links: req.links }
      @db[resource].push item
      @render res, [item]
      @emit 'POST', resource, item
    else
      @render res, []

  onPATCH: (req, res)->
    [ resource, key, value ] = @parseURL req.url
    @db[resource] ?= []
    result = @filterResult @db[resource], { resource: resource, key: key, value: value }
    @merge k, req.body for k in result
    @emit 'PATCH', resource, result, req.body
    @render res, result

  onPUT: (req, res)->
    [ resource, key, value ] = @parseURL req.url
    @db[resource] ?= []
    result = @filterResult @db[resource], { resource: resource, key: key, value: value }
    for item in result
      item.links.push link for link in req.body.links if req.body.links?
    @emit 'PUT', resource, result, req.body
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
      @db[resource] = @db[resource].filter((x) -> (String(x.props[key]) != decodeURIComponent(String(value))) or (!result.push x))
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

  hook: (fn)->
    @hooks.push fn

  runHooks: (req, res, arr, done)->
    return done() if arr.length is 0
    arr.shift() req, res, (err)=>
      return done err if err
      @runHooks req, res, arr, done

  onRequest: (req, res)->
    @writeHead res
    @extendResponse req, res
    req.resource = @getResource req.url
    req.extension = @getExtension req.url
    method = req.method.toLowerCase()

    @log.info req.method, req.url

    @runHooks req, res, [].concat(@hooks...), (err)=>
      if err
        res.end err.message
        @emit 'error', err
      else
        if @methods[method]?
          @methods[method] req, res
        else
          err = new Error('Method not supported.')
          res.end err.message
          @emit 'error', err
        @emit 'request', req, res

  start: ->
    @server.listen @config.port, =>
      @log.info {port: @config.port}, "server started"
      @emit 'start'
    return @

  stop: ->
    @server.close()
    @emit 'stop'
    return @

  logPluginEvents: (plugin)->
    unless plugin.on?
      @log.warn {plugin: plugin.name}, "not an event emitter"
      return

    plugin.on 'info', (args...) =>
      @log.info {plugin: plugin.name}, args...
    plugin.on 'error', (args...)=>
      @log.error {plugin: plugin.name}, args...

module.exports = (config)->
  return new Hotcoffee config
