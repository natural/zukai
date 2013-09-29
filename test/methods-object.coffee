{createClient} = require 'riakpbc'
{Model} = require '../src/model'
assert = require 'assert'


describe 'Object Methods', ->
  before (done)->
    @model = new Model
      name: 'A'
      bucket: 'test-methods-object'
      connection: createClient()
    done()

  describe 'put method', ->
    it 'should create objects', (done)->
      self = @
      model = @model
      a0 = model.create {}
      a0.put (err, obj)->
        assert not err
        assert obj == a0
        self.key = obj.key
        done()

  describe 'get method', ->
    it 'should read objects', (done)->
      model = @model
      key = @key
      model.get key, (err, obj)->
        assert not err
        assert obj.key == key
        done()

  describe 'del method', ->
    it 'should remove objects', (done)->
      model = @model
      key = @key
      model.get key, (err, obj)->
        assert not err
        obj.del (err)->
          assert not err
          model.get key, (err, obj)->
            assert not err
            assert not obj
            done()
