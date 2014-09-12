# file: test/unit/test_plugin_mongodb

describe 'mongodb Plugin', ->
  beforeEach ->
    @plugin = require("#{__dirname}/../../src/plugins/mongo_db")

  it 'should be awesome', ->