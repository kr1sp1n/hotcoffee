# file: plugins/mongodb.coffee

class Plugin

  constructor: (@app, @opts)->
    @name = 'mongodb'
    @collections = {}
    @client = require('mongodb').MongoClient
    @db = null
    @registerEvents()
    if @opts?.url?
      @connect (err)=>
        console.log "Connected to #{@opts.url}"
        @db.collectionNames namesOnly: true, (err, names)=>
          @loadCollection name.split('.')[1] for name in (names.filter (name)-> name.split('.')[1] != "system")

  connect: (done)->
    @client.connect @opts.url, (err, @db)=>
      done err

  loadCollection: (resource)->
    @collections[resource] = @db.collection resource
    cursor = @collections[resource].find({}).toArray (err, results)=>
      if results?.length > 0
        @app.db[resource] = results

  registerEvents: ->

    @app.on 'POST', (resource, data)=>
      unless @collections[resource]?
        @collections[resource] = @db.collection resource
      @collections[resource].insert data, (err, docs)->

    @app.on 'DELETE', (resource, data)=>
      if @collections[resource]?
        ids = data.map (x)-> x._id
        selector = {'_id':{$in:ids}}
        @collections[resource].remove selector, (err, count)->

    @app.on 'PATCH', (resource, items, data)=>
      if @collections[resource]?
        ids = items.map (x)-> x._id
        opts = multi: true
        selector = {'_id':{$in:ids}}
        @collections[resource].update selector, {$set:data}, opts, (err, count)->

module.exports = (app, opts)->
  return new Plugin app, opts