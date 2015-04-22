# file: test/unit/test_hotcoffee.coffee

should = require 'should'
sinon = require 'sinon'
EventEmitter = require('events').EventEmitter

toOutput = (result, href)->
  output = {
    items: result
    href: href
  }
  JSON.stringify(output, null, 2) + '\n'

describe 'Hotcoffee', ->
  beforeEach ->
    @process = sinon.stub new EventEmitter()
    @process.env = {}
    @process.exit = sinon.stub()
    @req = new EventEmitter()
    @req.method = 'GET'
    @req.url = "/turtles/name/Donatello"
    @req.end = sinon.stub()
    @req.headers = {}
    @req.body = {}
    @req.send = (data)=>
      @req.emit 'data', data
      @req.emit 'end'

    @res =
      endpoint: 'http://localhost:1337'
      end: sinon.stub()
      writeHead: sinon.stub()
      setHeader: sinon.stub()
      req: @req

    @links = links = [ { rel: 'friend', type: 'application/json', href: [@res.endpoint, 'id', 3].join('/') } ]

    @log =
      info: sinon.stub()
      error: sinon.stub()
      warn: sinon.stub()

    @hotcoffee = require("#{__dirname}/../../index")(process: @process, log: @log)
    @hotcoffee.server =
      listen: sinon.stub()
      close: sinon.stub()

    @hotcoffee.db =
      resource1: [
        { type: 'resource1', props: { id: 1 }, links: [] }
        { type: 'resource1', props: { id: 2, name: 'hello' }, links: [] }
        { type: 'resource1', props: { id: 3, name: 'world' }, links: [] }
      ]
      resource2: []

    @plugin = (app, opts)=>
      plugin = new EventEmitter()
      plugin.name = 'Superplugin'
      plugin.opts = opts
      return plugin

    @mygreatformat.reset() if @mygreatformat?.reset?

    @mygreatformat = sinon.spy (res, result)->
      output = result.map (x)-> "#{JSON.stringify(x)}"
      res.setHeader 'Content-Type', 'text/mygreatformat; charset=utf-8'
      res.end output

    @format =
      'mgf': @mygreatformat # file extension
      'text/mygreatformat': @mygreatformat #Mime type

  describe 'init(config, done)', ->
    beforeEach ->
      @config =
        port: 8888
        log: @log

    it 'should initialize with a valid config', (done)->
      @hotcoffee.init @config, (err)=>
        @hotcoffee.config.port.should.equal @config.port
        done err

    it 'should emit an "init" event with config', (done)->
      @hotcoffee.on 'init', (config)=>
        config.should.equal @config
        done null
      @hotcoffee.init @config

  describe 'use(fn, opts)', ->

    it 'should register new plugins', ->
      @hotcoffee.use @plugin
      @hotcoffee.plugins.should.have.property 'Superplugin'

    it 'should emit a "use" event with fn and opts', (done)->
      options =
        test: 1
      @hotcoffee.on 'use', (fn, opts)=>
        fn.should.be.Function
        opts.should.equal options
        done null
      @hotcoffee.use @plugin, options

    it 'should log info events from the plugin', ->
      @hotcoffee.use @plugin
      @hotcoffee.plugins['Superplugin'].emit 'info', 'info event'
      @log.info.calledOnce.should.be.true
      @log.info.calledWith({plugin: 'Superplugin'}, 'info event').should.be.true

    it 'should log error events from the plugin', ->
      @hotcoffee.use @plugin
      @hotcoffee.plugins['Superplugin'].emit 'error', 'error event'
      @log.error.calledOnce.should.be.true
      @log.error.calledWith({plugin: 'Superplugin'}, 'error event').should.be.true

    it 'should not try to log for non emit plugins', ->
      @hotcoffee.use (app, config) ->
        return {name: 'test'}
      @log.warn.calledOnce.should.be.true
      @log.warn.calledWith({plugin: 'test'}, 'not an event emitter').should.be.true

  describe 'accept(format)', ->

    it 'should extend accepted formats', ->
      @hotcoffee.accept @format
      @hotcoffee.formats.should.have.property 'mgf'
      @hotcoffee.formats.should.have.property 'text/mygreatformat'

    it 'should overwrite existing formats', ->
      new_json_format = (res, result)->
        res.end 'lala'
      formats =
        'json': new_json_format
      @hotcoffee.accept formats
      @hotcoffee.formats.json.should.equal new_json_format


  describe 'isRoot(url)', ->

    it 'should return true if req.url is "/"', ->
      req = url: '/'
      @hotcoffee.isRoot(req.url).should.be.ok

    it 'should return false if req.url is not "/"', ->
      req = url: '/hello'
      @hotcoffee.isRoot(req.url).should.be.false


  describe 'onExit()', ->

    beforeEach ->
      @process.exit.restore() if @process.exit.restore?

    it 'should emit an "exit" event', (done)->
      @hotcoffee.on 'exit', done
      @hotcoffee.onExit()


  describe 'onSIGINT()', ->

    beforeEach ->
      @process.exit.restore() if @process.exit.restore?
      @hotcoffee.onExit.reset() if @hotcoffee.onExit.reset?
      @onExit = sinon.spy @hotcoffee, 'onExit'

    it 'should call onExit()', ->
      @hotcoffee.onSIGINT()
      @onExit.calledOnce.should.be.ok

    it 'should exit the process with 0', ->
      @hotcoffee.onSIGINT()
      @process.exit.calledOnce.should.be.ok
      @process.exit.calledWith(0).should.be.ok


  describe 'merge(dest, source)', ->

    beforeEach ->
      @dest =
        props:
          test: 0
      @source =
        test: 1
        hello: 'world'

    it 'should replace all `props` values from dest if source has the same keys', ->
      @hotcoffee.merge @dest, @source
      @dest.props.test.should.equal 1

    it 'should add new keys to dest that are present in source', ->
      @hotcoffee.merge @dest, @source
      @dest.props.should.have.property 'hello', @source['hello']


  describe 'writeHead(res)', ->

    it 'should write HTTP headers to res', ->
      @hotcoffee.writeHead @res
      @res.setHeader.called.should.be.ok


  describe 'parseURL(url)', ->

    it 'should split the url.pathname by "/" to return 3-items array', ->
      expected = ['turtles', 'name', 'Donatello']
      arr = @hotcoffee.parseURL @req.url
      arr.should.have.lengthOf 3
      arr[i].should.equal(expected[i]) for i in [0..2]

    it 'should leave out the extension if there is one', ->
      extension = '.json'
      @req.url = @req.url+extension
      expected = ['turtles', 'name', 'Donatello']
      arr = @hotcoffee.parseURL @req.url
      arr[2].should.equal 'Donatello'


  describe 'parseBody(req, done)', ->

    it 'should parse the body of a req stream to an object', (done)->
      @hotcoffee.parseBody @req, @res, (err, body)=>
        body.should.have.property 'hello', 'world'
        done err
      @req.send 'hello=world'

  describe 'mapResult(res, result)', ->

    it 'should execute the right format function from HTTP accept header', ->
      @mygreatformat.reset()
      @hotcoffee.accept @format
      @res.req.headers['accept'] = 'text/mygreatformat'
      @hotcoffee.mapResult @res, @hotcoffee.db.resource1
      @mygreatformat.calledOnce.should.be.ok

    it 'should execute the right format function from file extension', ->
      @mygreatformat.reset()
      @hotcoffee.accept @format
      @req.url = @req.url+'.mgf'
      @req.extension = @hotcoffee.getExtension @req.url
      @hotcoffee.mapResult @res, @hotcoffee.db.resource1
      @mygreatformat.calledOnce.should.be.ok


  describe 'onGET(req, res)', ->

    it 'should emit a "GET" event with req and res', (done)->
      @hotcoffee.on 'GET', (req, res)=>
        req.url.should.equal @req.url
        should(res).be.ok
        done null
      @hotcoffee.onGET @req, @res

    it 'should response all items of a resource type', ->
      resource = 'resource1'
      @req.url = '/' + resource
      output = toOutput @hotcoffee.db[resource], @res.endpoint + @req.url
      @hotcoffee.onGET @req, @res
      @res.end.calledOnce.should.be.ok
      @res.end.calledWith(output).should.be.ok

    it 'should response items that have a specific key', ->
      resource = 'resource1'
      key = 'name'
      @req.url = "/#{resource}/#{key}"
      output = toOutput (@hotcoffee.db[resource].filter (x)-> x.props[key]?), @res.endpoint + @req.url
      @hotcoffee.onGET @req, @res
      @res.end.calledOnce.should.be.ok
      @res.end.calledWith(output).should.be.ok

    it 'should response items that match a specific value of a key', ->
      resource = 'resource1'
      key = 'name'
      value = 'hello'
      @req.url = "/#{resource}/#{key}/#{value}"
      output = toOutput (@hotcoffee.db[resource].filter (x)-> String(x.props[key])==String(value)), @res.endpoint + @req.url
      @hotcoffee.onGET @req, @res
      @res.end.calledOnce.should.be.ok
      @res.end.calledWith(output).should.be.ok

    it 'should populate all resources if req.url == "/"', ->
      resources = ({ type:'resource', href:[@res.endpoint, name].join('/'), props: { name: name } } for name of @hotcoffee.db)
      @req.url = '/'
      output = toOutput resources, @res.endpoint + @req.url
      @hotcoffee.onGET @req, @res
      @res.end.calledOnce.should.be.ok
      @res.end.calledWith(output).should.be.ok


  describe 'onPOST(req, res)', ->

    it 'should response an empty array if resource name is empty', (done)->
      @req.url = "/"
      output = toOutput [], @res.endpoint + @req.url
      @hotcoffee.on 'render', (res, result)=>
        result.should.be.empty
        @res.end.calledOnce.should.be.ok
        @res.end.calledWith(output).should.be.ok
        done null
      @hotcoffee.onPOST @req, @res
      @req.send()

    it 'should emit a "POST" event with resource and item', (done)->
      resource = 'resource2'
      @req.url = "/#{resource}"
      @hotcoffee.db[resource].should.be.empty
      @hotcoffee.on 'POST', (resource_name, item)=>
        resource.should.equal resource_name
        @hotcoffee.db[resource].should.have.lengthOf 1
        item.props.should.have.property 'hello', 'world'
        done null
      # simulate body parser that gets executed only in onRequest function
      @req.body =
        hello: 'world'
      @hotcoffee.onPOST @req, @res
      @req.send 'hello=world'


  describe 'onPATCH(req, res)', ->

    it 'should emit a "PATCH" event with resource, result and body', (done)->
      resource = 'resource1'
      key = 'id'
      @req.url = "/#{resource}/#{key}"
      @hotcoffee.on 'PATCH', (resource_name, result, body)->
        resource_name.should.equal resource
        done null
      @hotcoffee.onPATCH @req, @res
      @req.send 'hello=world'

    it 'should create an empty array if resource does not exist', (done)->
      resource = 'turtle'
      @req.url = "/#{resource}"
      output = toOutput [], @res.endpoint + @req.url
      @hotcoffee.on 'render', (res, result)=>
        result.should.be.empty
        @res.end.calledOnce.should.be.ok
        @res.end.calledWith(output).should.be.ok
        done null
      @hotcoffee.onPATCH @req, @res
      @req.send 'hello=world'

    it 'should modify the items that match a specific value of a key', (done)->
      resource = 'resource1'
      key = 'id'
      value = 2
      @req.url = "/#{resource}/#{key}/#{value}"
      @hotcoffee.on 'render', (res, result)=>
        result.should.have.lengthOf 1
        output = toOutput (@hotcoffee.db[resource].filter (x)-> String(x.props[key])==String(value)), @res.endpoint + @req.url
        @res.end.calledOnce.should.be.ok
        @res.end.calledWith(output).should.be.ok
        done null
      @hotcoffee.onPATCH @req, @res
      @req.send 'name=goodbye'


  describe 'onPUT(req, res)', ->

    it 'should link resources to other resources', (done)->
      resource = 'resource1'
      key = 'id'
      value = 2
      @req.url = "/#{resource}/#{key}/#{value}"
      @hotcoffee.on 'render', (res, result)=>
        result.should.have.lengthOf 1
        result[0].links.should.eql @links
        done null
      # simulate body parser
      @req.body =
        links: @links
      @hotcoffee.onPUT @req, @res
      @req.send "links=#{JSON.stringify(@links)}"

    it 'should create an empty array if resource does not exist', (done)->
      resource = 'does_not_exist'
      @req.url = "/#{resource}"
      output = toOutput [], @res.endpoint + @req.url
      @hotcoffee.on 'render', (res, result)=>
        result.should.be.empty
        @res.end.calledOnce.should.be.ok
        @res.end.calledWith(output).should.be.ok
        done null
      @hotcoffee.onPUT @req, @res
      @req.send "links=#{JSON.stringify(@links)}"


  describe 'onDELETE(req, res)', ->

    it 'should emit a "DELETE" event with resource and result', (done)->
      resource = 'resource1'
      key = 'id'
      value = 3
      @req.url = "/#{resource}/#{key}/#{value}"
      @hotcoffee.on 'DELETE', (resource_name, result)->
        resource_name.should.equal resource
        result.should.have.lengthOf 1
        result[0].props.should.have.property 'id', value
        done null
      @hotcoffee.onDELETE @req, @res

    it 'should delete a resource collection if requested', (done)->
      resource = 'resource1'
      @hotcoffee.db[resource].should.have.lengthOf 3
      @req.url = "/#{resource}"
      output = toOutput @hotcoffee.db[resource], @res.endpoint + @req.url
      @hotcoffee.on 'render', (res, result)=>
        @res.end.calledOnce.should.be.ok
        @res.end.calledWith(output).should.be.ok
        should(@hotcoffee.db[resource]).not.be.ok
        done null
      @hotcoffee.onDELETE @req, @res

    it 'should create an empty array if resource does not exist', (done)->
      resource = 'turtles'
      @req.url = "/#{resource}"
      output = toOutput [], @res.endpoint + @req.url
      @hotcoffee.on 'render', (res, result)=>
        result.should.be.empty
        @res.end.calledOnce.should.be.ok
        @res.end.calledWith(output).should.be.ok
        done null
      @hotcoffee.onDELETE @req, @res


  describe 'onRequest(req, res)', ->

    it 'should emit a "request" event with req and res', (done)->
      @req.url = '/'
      @hotcoffee.on 'request', (req, res)=>
        req.url.should.equal '/'
        done null
      @hotcoffee.onRequest @req, @res
      @req.send()

    it 'should respond an error if HTTP method is not supported', (done)->
      @req.method = 'STUPID'
      errorMessage = "Method not supported."
      @hotcoffee.on 'error', (err)=>
        @res.end.calledOnce.should.be.ok
        @res.end.calledWith(errorMessage).should.be.ok
        done null
      @hotcoffee.onRequest @req, @res
      @req.send()

    it 'should respond any error from a hook', (done)->
      errorMessage = 'Any error'
      @hotcoffee.hook (req, res, next)->
        next new Error errorMessage
      @hotcoffee.on 'error', (err)=>
        @res.end.calledOnce.should.be.ok
        @res.end.calledWith(errorMessage).should.be.ok
        done null
      @hotcoffee.onRequest @req, @res
      @req.send()


  describe 'start()', ->
    beforeEach ->
      @hotcoffee.server.listen.callsArg 1

    it 'should emit the running port', (done) ->
      @hotcoffee.on 'start', =>
        @log.info.calledWith({port: 1337}, "server started").should.be.true
        done()
      @hotcoffee.start()

    it 'should emit a "start" event', (done)->
      @hotcoffee.on 'start', ->
        done null
      @hotcoffee.start()

    it 'should listen on the configured port', ->
      port = @hotcoffee.config.port
      @hotcoffee.start()
      @hotcoffee.server.listen.calledOnce.should.be.ok
      @hotcoffee.server.listen.calledWith(port).should.be.ok


  describe 'stop()', ->

    it 'should emit a "stop" event', (done)->
      @hotcoffee.on 'stop', ->
        done null
      @hotcoffee.stop()


  describe 'hook(fn)', ->

    it 'should add a function to hooks', ->
      fn = (req, res, next)->
      hooksBefore = @hotcoffee.hooks.length
      @hotcoffee.hook fn
      @hotcoffee.hooks.length.should.equal hooksBefore + 1


  describe 'runHooks(req, res, arr, done)', (done)->

    it 'should run all passed hooks', (done)->
      counter = 0
      hook1 = (req, res, next)->
        counter+=1
        next null
      hook2 = (req, res, next)->
        counter+=1
        next null

      hooks = [hook1, hook2]
      @hotcoffee.runHooks @req, @res, hooks, (err)->
        counter.should.equal 2
        done err

    it 'should propagate any error inside a hook', (done)->
      err1 = new Error 'An error'
      hook1 = (req, res, next)-> next null
      hook2 = (req, res, next)-> next err1
      hooks = [hook1, hook2]
      @hotcoffee.runHooks @req, @res, hooks, (err)->
        err.should.equal err1
        done null

    it 'should stop executing further hooks if any error occurs', (done)->
      hook1 = (req, res, next)-> next new Error('Any error')
      hook2 = sinon.spy (req, res, next)-> next null
      hooks = [hook1, hook2]
      @hotcoffee.runHooks @req, @res, hooks, (err)->
        hook2.called.should.not.be.ok
        done null
