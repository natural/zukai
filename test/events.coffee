{createClient} = require 'riakpbc'
{createModel} = require '../src/model'
assert = require 'assert'


describe 'Events', ->
  beforeEach (done)->
    @model = createModel
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
      model = @model
      model.server.on 'create', (inst)->
        assert inst.doc.name == 'alice'
        model.server.removeAllListeners 'create'
        done()
      alice = model.create doc: name:'alice', age:21

  describe 'delete event', ->
    it 'should fire', (done)->
      model = @model
      model.server.on 'del', (key)->
        assert key == alice.key
        model.server.removeAllListeners 'delete'
        done()
      alice = model.create doc: name:'alice', age:21
      alice.put().then ->
        alice.del().then(->)

  describe 'put event', ->
    it 'should fire', (done)->
      model = @model
      model.server.on 'put', (inst)->
        assert inst.doc.name == 'alice'
        model.server.removeAllListeners 'put'
        done()
      alice = model.create doc: name:'alice', age:21
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

      Loud.server.on '*', (inst)->
        done()
      Loud.create doc: name:'alice', age:32

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

      Loud.server.on 'newListener', ->
        done()
      Loud.server.on 'create', (inst)->
      Loud.create doc: name:'alice', age:32
