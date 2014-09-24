# file: test/unit/test_plugin_mongodb

should = require 'should'
sinon = require 'sinon'
EventEmitter = require('events').EventEmitter

describe 'mongo_db Plugin', ->
  beforeEach ->
    @app = new EventEmitter()
    @turtles = [
      { id: 1, _id: 1, name: 'Donatello' }
      { id: 2, _id: 2, name: 'Leonardo' }
      { id: 3, _id: 3, name: 'Michelangelo' }
      { id: 4, _id: 4, name: 'Raphael' }
    ]
    @app.db = {}
    @db =
      collectionNames: sinon.stub()
      collection: sinon.stub()
    @collection =
      find: sinon.stub()
      toArray: sinon.stub()
      insert: sinon.stub()
      update: sinon.stub()
      remove: sinon.stub()

    @collection.toArray.yields null, @turtles
    @collection.find.returns @collection
    @db.collection.returns @collection

    @db.collectionNames.callsArgWith 1, null, ["hotcoffee.turtles"]
    @client =
      connect: sinon.stub() 
    @client.connect.callsArgWith 1, null, @db # stub callback
    @opts = 
      url: "fake_mongodb_url"
      client: @client
    @plugin = require("#{__dirname}/../../src/plugins/mongo_db")(@app, @opts)

  it 'should expose its right name', ->
    @plugin.name.should.equal 'mongo_db'


  describe 'connect(done)', ->

    it 'should connect to MongoDB if opts.url is set', (done)->
      @plugin.connect (err)=>
        done err

    it 'should return an error if no MongoDB URL was set', (done)->
      @plugin.opts.url = null
      @plugin.connect (err)=>
        should(err).be.ok
        err.message.should.equal "No MongoDB URL set"
        done null


  describe 'loadCollection(resource)', ->

    it 'should load MongoDB collections in the app DB', ->
      resource = 'turtles'
      @plugin.loadCollection resource
      @db.collection.called.should.be.ok
      @db.collection.calledWith(resource).should.be.ok
      @app.db[resource].should.equal @turtles


  describe 'registerEvents()', ->

    it 'should listen on "POST" events of the app', ->
      resource = 'beatles'
      data = name: 'John Lennon'
      @plugin.registerEvents()
      @app.emit 'POST', resource, data
      @db.collection.calledWith(resource).should.be.ok
      @collection.insert.called.should.be.ok
      @collection.insert.calledWith(data).should.be.ok

    it 'should listen on "PATCH" events of the app', ->
      resource = 'turtles'
      items = @turtles
      data = status: 'hungry'
      @plugin.registerEvents()
      @app.emit 'PATCH', resource, items, data
      @collection.update.called.should.be.ok

    it 'should listen on "DELETE" events of the app', ->
      resource = 'turtles'
      items = @turtles
      @plugin.registerEvents()
      @app.emit 'DELETE', resource, items
      @collection.remove.called.should.be.ok


