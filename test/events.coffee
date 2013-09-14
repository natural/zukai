assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src/model'


Model = null


describe 'Events', ->
  beforeEach (done)->
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
      Model.server.on 'create', (inst)->
        assert inst.doc.name == 'alice'
        Model.server.removeAllListeners 'create'
        done()

      alice = Model.create doc: name:'alice', age:21

  describe 'delete event', ->
    it 'should fire', (done)->
      Model.on 'del', (inst)->
        assert inst.doc.name == 'alice'
        Model.removeAllListeners 'delete'
        done()
      alice = Model.create name:'alice', age:21
      alice.put().then ->
        alice.del().then(->)

  describe 'put event', ->
    it 'should fire', (done)->
      Model.on 'put', (inst)->
        assert inst.doc.name == 'alice'
        Model.removeAllListeners 'put'
        done()
      alice = Model.create name:'alice', age:21
      alice.put().then ->
        alice.del().then(->)

  describe 'event emitter options', ->
    it 'should send wildcard events with wildcard:true', (done)->
      Loud = createModel
        name: 'Loud'
        connection: createClient()
        events:
          wildcard: true
        schema:
          properties:
            name:
              type: 'string'
            age:
              type: 'number'

      Loud.on '*', (inst)->
        done()
      Loud.create name:'alice', age:32

    it 'should emit newListener event with newListener:true', (done)->
      Loud = createModel
        name: 'Loud'
        connection: createClient()
        events:
          newListener: true
        schema:
          properties:
            name:
              type: 'string'
            age:
              type: 'number'

      Loud.on 'newListener', ->
        done()
      Loud.on 'create', (inst)->
      Loud.create name:'alice', age:32
