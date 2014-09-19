# file: test/unit/test_hotcoffee

should = require 'should'
sinon = require 'sinon'
EventEmitter = require('events').EventEmitter

toOutput = (obj)->
  JSON.stringify(obj, null, 2) + '\n'

describe 'HotCoffee', ->
  beforeEach ->
    @req = new EventEmitter()
    @req.method = 'GET'
    @req.url = "/turtles/name/Donatello"
    @req.end = sinon.stub()
    @req.send = (data)=>
      @req.emit 'data', data 
      @req.emit 'end'

    @res =
      end: sinon.stub()
      writeHead: sinon.stub()

    @hotcoffee = require("#{__dirname}/../../src/hot")()
    @hotcoffee.server = 
      listen: sinon.stub()
      close: sinon.stub()

    @hotcoffee.db = 
      resource1: [
        { id: 1 }
        { id: 2, name: 'hello' }
        { id: 3, name: 'world' }
      ]
      resource2: []

    @plugin = (app, opts)=>
      return name: 'Superplugin', opts: opts


  describe 'init(config, done)', ->
    beforeEach ->
      @config =
        port: 8888

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


  describe 'isRoot(url)', ->

    it 'should return true if req.url is "/"', ->
      req = url: '/'
      @hotcoffee.isRoot(req.url).should.be.ok

    it 'should return false if req.url is not "/"', ->
      req = url: '/hello'
      @hotcoffee.isRoot(req.url).should.be.false


  describe 'onExit()', ->
    beforeEach ->
      process.exit.restore() if process.exit.restore?
      @exit = sinon.stub process, 'exit'

    it 'should emit an "exit" event', (done)->
      @hotcoffee.on 'exit', done
      @hotcoffee.onExit()


  describe 'onSIGINT()', ->

    beforeEach ->
      process.exit.restore() if process.exit.restore?
      @hotcoffee.onExit.restore() if @hotcoffee.onExit.restore?
      @exit = sinon.stub process, 'exit'
      @onExit = sinon.spy @hotcoffee, 'onExit'

    it 'should call onExit()', ->
      @hotcoffee.onSIGINT()
      @onExit.calledOnce.should.be.ok

    it 'should exit the process with 0', ->
      @hotcoffee.onSIGINT()
      @exit.calledOnce.should.be.ok
      @exit.calledWith(0).should.be.ok


  describe 'merge(dest, source)', ->

    beforeEach ->
      @dest =
        test: 0
      @source = 
        test: 1
        hello: 'world'

    it 'should replace all values from dest if source has the same keys', ->
      @hotcoffee.merge @dest, @source
      @dest.test.should.equal 1

    it 'should add new keys to dest that are present in source', ->
      @hotcoffee.merge @dest, @source
      @dest.should.have.property 'hello', @source['hello']


  describe 'writeHead(res)', ->

    it 'should write HTTP headers to res', ->
      @hotcoffee.writeHead @res
      @res.writeHead.calledOnce.should.be.ok


  describe 'parseURL(url)', ->

    it 'should split the url.pathname by "/" to return 3-items array', ->
      expected = ['turtles', 'name', 'Donatello']
      arr = @hotcoffee.parseURL @req.url
      arr.should.have.lengthOf 3
      arr[i].should.equal(expected[i]) for i in [0..2]


  describe 'parseBody(req, done)', ->

    it 'should parse the body of a req stream to an object', (done)->
      @hotcoffee.parseBody @req, (err, body)=>
        body.should.have.property 'hello', 'world'
        done err
      @req.send 'hello=world'


  describe 'onGET(req, res)', ->

    it 'should emit a "GET" event with req and res', (done)->
      @hotcoffee.on 'GET', (req, res)=>
        req.url.should.equal @req.url
        should(res).be.ok
        done null
      @hotcoffee.onGET @req, @res

    it 'should response all items of a resource type', ->
      resource = 'resource1'
      output = toOutput @hotcoffee.db[resource]
      @req.url = '/' + resource
      @hotcoffee.onGET @req, @res
      @res.end.calledOnce.should.be.ok
      @res.end.calledWith(output).should.be.ok

    it 'should response items that have a specific key', ->
      resource = 'resource1'
      key = 'name'
      output = toOutput (@hotcoffee.db[resource].filter (x)-> x[key]?)
      @req.url = "/#{resource}/#{key}"
      @hotcoffee.onGET @req, @res
      @res.end.calledOnce.should.be.ok
      @res.end.calledWith(output).should.be.ok

    it 'should response items that match a specific value of a key', ->
      resource = 'resource1'
      key = 'name'
      value = 'hello'
      output = toOutput (@hotcoffee.db[resource].filter (x)-> String(x[key])==String(value))
      @req.url = "/#{resource}/#{key}/#{value}"
      @hotcoffee.onGET @req, @res
      @res.end.calledOnce.should.be.ok
      @res.end.calledWith(output).should.be.ok

    it 'should populate all resources if req.url == "/"', ->
      output = toOutput (name for name, val of @hotcoffee.db)
      @req.url = '/'
      @hotcoffee.onGET @req, @res
      @res.end.calledOnce.should.be.ok
      @res.end.calledWith(output).should.be.ok


  describe 'onPOST(req, res)', ->

    it 'should response an empty array if resource name is empty', (done)->
      output = toOutput []
      @req.url = "/"
      @hotcoffee.on 'render', (res, result)=>
        result.should.be.empty
        @res.end.calledOnce.should.be.ok
        @res.end.calledWith(output).should.be.ok
        done null
      @hotcoffee.onPOST @req, @res
      @req.send 'hello=world'

    it 'should emit a "POST" event with resource and body', (done)-> 
      resource = 'resource2'
      @req.url = "/#{resource}"
      @hotcoffee.db[resource].should.be.empty
      @hotcoffee.on 'POST', (resource_name, body)=>
        resource.should.equal resource_name
        @hotcoffee.db[resource].should.have.lengthOf 1
        body.should.have.property 'hello', 'world'
        done null
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
      resource = 'turtles'
      output = toOutput []
      @req.url = "/#{resource}"
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
        output = toOutput (@hotcoffee.db[resource].filter (x)-> String(x[key])==String(value))
        @res.end.calledOnce.should.be.ok
        @res.end.calledWith(output).should.be.ok
        done null
      @hotcoffee.onPATCH @req, @res
      @req.send 'name=goodbye'


  describe 'onDELETE(req, res)', ->

    it 'should emit a "DELETE" event with resource and result', (done)->
      resource = 'resource1'
      key = 'id'
      value = 3
      @req.url = "/#{resource}/#{key}/#{value}"
      @hotcoffee.on 'DELETE', (resource_name, result)->
        resource_name.should.equal resource
        result.should.have.lengthOf 1
        result[0].should.have.property 'id', value
        done null
      @hotcoffee.onDELETE @req, @res

    it 'should delete a resource collection if requested', (done)->
      resource = 'resource1'
      @hotcoffee.db[resource].should.have.lengthOf 3
      @req.url = "/#{resource}"
      output = toOutput @hotcoffee.db[resource]
      @hotcoffee.on 'render', (res, result)=>
        @res.end.calledOnce.should.be.ok
        @res.end.calledWith(output).should.be.ok
        should(@hotcoffee.db[resource]).not.be.ok
        done null
      @hotcoffee.onDELETE @req, @res

    it 'should create an empty array if resource does not exist', (done)->
      resource = 'turtles'
      output = toOutput []
      @req.url = "/#{resource}"
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

    it 'should respond an error if HTTP method is not supported', ->
      @req.method = 'STUPID'
      output = "Method not supported.\n"
      @hotcoffee.onRequest @req, @res
      @res.end.calledOnce.should.be.ok
      @res.end.calledWith(output).should.be.ok


  describe 'start()', ->

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



