# file: test/unit/test_hotcoffee

should = require 'should'

describe 'HotCoffee', ->
  beforeEach ->
    @hotcoffee = require("#{__dirname}/../../hot")()
    @plugin = (app, opts)=>
      return name: 'Superplugin', opts: opts

  describe 'init(config, done)', ->
    beforeEach ->
      @config =
        port: 8888

    it 'should initialize with a valid config', (done)->
      @hotcoffee.init @config, (err)=>
        @hotcoffee.port.should.equal @config.port
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
