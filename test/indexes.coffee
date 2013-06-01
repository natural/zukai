assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src'


Model = IndexedModel = null


describe 'Indexes', ->
  before (done)->
    Model = createModel 'foo',
      connection: createClient()
      indexes: ->
        null

    IndexedModel = createModel 'bar',
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
    it 'should be present on Models and objects', (done)->
      assert Model.indexes?
      assert Model.create().indexes?

      assert typeof Model.indexes == 'function'
      assert typeof Model.create().indexes == 'function'

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
