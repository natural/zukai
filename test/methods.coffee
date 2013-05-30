assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src'


Model = instance = null


describe 'Methods', ->
  describe 'create', ->
    it 'should make a new model instance', (done)->
      Model = createModel
        name: 'methodcheck'
        connection: createClient()
        schema:
          properties:
            val:
              type: 'number'

      instance = Model.create 'known-key', val:0
      done()

  describe 'save when', ->
    it 'should not return an error', (done)->
      instance.put().then (inst)->
        assert inst.key == instance.key
        done()

  describe 'save after change', ->
    it 'should not return an error', (done)->
      newval = 4321
      instance.doc.val = newval
      instance.put().then (inst)->
        assert inst.key == instance.key

        Model.get(instance.key).then (other)->
          assert other.doc.val == newval
          done()

  describe 'delete', ->
    it 'should not return an error', (done)->
      ok = (reply)->
        Model.get(instance.key).then (other)->
          assert not other
          done()
      er = (reason)->
        assert 0
      instance.del().then ok, er

  describe 'toJSON', ->
    it 'should return the document', ->
      assert instance.toJSON().val == instance.doc.val
      assert instance.toJSON() == instance.doc

  describe 'inheritance', ->
    it 'should allow methods to be replaced', (done)->
      arg1 = 1
      arg2 = 2

      Fruit = createModel
        name: 'fruit'
        del: (cb)->
          # not promise based
          cb arg1, arg2

      grapes = Fruit.create()
      grapes.del (a, b)->
        assert a == arg1
        assert b == arg2
        done()
