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

  describe 'save event', ->
    it 'should fire', (done)->
      Model.on 'save', (inst)->
        assert inst.doc.name == 'alice'
        Model.removeAllListeners 'save'
        done()
      alice = Model.create name:'alice', age:21
      alice.save (err, doc)->
        assert not err
        alice.del (->)
