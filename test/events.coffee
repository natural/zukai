assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src'


Model = null


describe 'Events', ->
  before (done)->
    Model = createModel
      name: 'eventcheck'
      connection: createClient()
      schema:
        properties:
          name:
            type: 'string'
          age:
            type: 'number'
    done()

  describe 'create event', ->
    it 'should fire', (done)->
      Model.on 'create', (inst)->
        assert inst.doc.name == 'alice'
        Model.removeAllListeners 'create'
        done()

      alice = Model.create name:'alice', age:21

  describe 'delete event', ->
    it 'should fire', (done)->
      Model.on 'delete', (inst)->
        assert inst.doc.name == 'alice'
        Model.removeAllListeners 'delete'
        done()
      alice = Model.create name:'alice', age:21
      alice.save (err, doc)->
        assert not err
        alice.del (->)

  describe 'insert event', ->
    it 'should fire', (done)->
      Model.on 'insert', (inst)->
        assert inst.doc.name == 'alice'
        Model.removeAllListeners 'insert'
        done()
      alice = Model.create name:'alice', age:21
      alice.save (err, doc)->
        assert not err
        alice.del (->)


  describe 'update event', ->
    it 'should fire', (done)->
      Model.on 'update', (inst)->
        assert inst.doc.name == 'alice'
        Model.removeAllListeners 'update'
        done()

      alice = Model.create name:'alice', age:21
      alice.save (err, doc)->
        assert not err
        alice.doc.age = 42
        alice.save (err, doc)->
          assert not err
          alice.del (->)
