# file: test/unit/test_hotcoffee

should = require 'should'
sinon = require 'sinon'
EventEmitter = require('events').EventEmitter

toOutput = (obj)->
  JSON.stringify(obj, null, 2) + '\n'

describe 'HotCoffee', ->
  beforeEach ->
    @req = new EventEmitter()
    @req.url = "/turtles/name/Donatello"
    @req.end = sinon.stub()

    @res =
      end: sinon.stub()
      writeHead: sinon.stub()

    @hotcoffee = require("#{__dirname}/../../src/hot")()
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
      @req.emit 'data', 'hello='
      @req.emit 'data', 'world' 
      @req.emit 'end'


  describe 'onGET(req, res)', ->

    beforeEach ->
      @hotcoffee.db = 
        resource1: [
          id: 1
          id: 2, name: 'hello'
          id: 3, name: 'world'
        ]
        resource2: []

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

    it 'should response items that have a specific property', ->
      resource = 'resource1'
      property = 'name'
      output = toOutput (@hotcoffee.db[resource].filter (x)-> x[property]?)
      @req.url = "/#{resource}/#{property}"
      @hotcoffee.onGET @req, @res
      @res.end.calledOnce.should.be.ok
      @res.end.calledWith(output).should.be.ok

    it 'should response items that match a specific value of a property', ->
      resource = 'resource1'
      property = 'name'
      value = 'hello'
      output = toOutput (@hotcoffee.db[resource].filter (x)-> String(x[property])==String(value))
      @req.url = "/#{resource}/#{property}/#{value}"
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
      # @hotcoffee.on 'render', (res, result)->
      #   @res.end.calledOnce.should.be.ok
      #   @res.end.calledWith(output).should.be.ok
      #   console.log @res.end.args
      #   done null
      @hotcoffee.onPOST @req, @res
      @req.emit 'data', 'hello='
      @req.emit 'data', 'world' 
      @req.emit 'end'
      done null



