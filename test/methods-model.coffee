{createClient} = require 'riakpbc'
{Model} = require '../src/model'
assert = require 'assert'


describe 'Model Methods', ->
  before (done)->
    @model = new Model
      name: 'A'
      bucket: 'test-methods-model'
      connection: createClient()
    done()

  describe 'keys method', ->
    it 'should fetch objects', (done)->
      self = @
      a0 = self.model.create {}
      a0.put (err, obj)->
        assert not err
        assert obj
        self.model.keys (response)->
          assert response.keys? != undefined
          assert response.keys.length >= 1
          done()

  describe 'get method', ->
    it 'should read objects', (done)->
      self = @
      a1 = self.model.create {}
      a1.put (err, obj)->
        assert not err
        assert obj
        assert obj.key
        self.key = obj.key
        self.model.get self.key, (err, obj)->
          assert not err
          assert obj.key == self.key
          done()

  describe 'del method', ->
    it 'should remove object by key', (done)->
      self = @
      self.model.get self.key, (err, obj)->
        assert not err
        obj.del (err)->
          assert not err
          self.model.get self.key, (err, obj)->
            assert not err
            assert not obj
            done()

  describe 'purge method', ->
    it 'should remove all objects from a bucket', (done)->
      self = @
      a2 = self.model.create {}
      a2.put (err, obj)->
        assert not err
        assert obj
        self.model.keys (response)->
          assert response.keys? != undefined
          assert response.keys.length >= 1
          self.model.purge (err)->
            assert not err
            done()
