{createClient} = require 'riakpbc'
{createModel} = require '../src/model'
assert = require 'assert'


describe 'Indexes', ->
  before (done)->
    @model = createModel
      name: 'foo'
      connection: createClient()
      indexes: ->

    @indexedModel = createModel
      name: 'bar'
      connection: createClient()
      indexes: ->
        [
          {key: 'name_bin', value: @doc.name.toString()}
          {key: 'age_bin', value: @doc.age.toString()}
        ]

      schema:
        properties:
          name:
            type: 'string'
          age:
            type: 'number'


    done()


  describe 'index function', ->
    it.only 'should be present on Models and objects', (done)->
      model = @model
      console.log model.indexes, model.name
      assert model.indexes?
#      assert model.create().indexes?

#      assert typeof model.indexes == 'function'
#      assert typeof model.create().indexes == 'function'

      done()

    it 'should produce arrays when called', (done)->
      i = IndexedModel.create 'indexed-key-thing', name: 'zack', age:88
      indexes = i.indexes()
      assert indexes.length == 2
      for idx in indexes
        assert idx.key
        assert idx.value
      done()


  describe 'put operations with indexes', ->
    it 'should send indexes when called', (done)->
      k = 'other-key-thing'
      i = IndexedModel.create k, name: 'xerxes', age:2531
      i.put(return_body:true).then (doc)->
        assert doc
        assert i.reply.content[0].indexes.length == 2

        i.indexSearch qtype:1, index:'name_bin', range_min:'a', range_max:'z',  (err, keys)->
          assert k in keys
          i.del().then done()
