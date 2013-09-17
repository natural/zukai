assert = require 'assert'
{each} = require 'underscore'
{createClient} = require 'riakpbc'
{createModel} = require '../src/model'


describe 'Schema Property Defaults', ->
  describe 'property without default', ->
    it 'should leave the property on the document undefined', (done)->
      Model = createModel
        name: 'noDefault'
        schema:
          properties:
            val:
              type: 'number'

      object = Model.create {}
      assert object
      assert object.doc
      assert object.doc.val == undefined
      done()

  describe 'property with simple default', ->
    it 'should create the property on the document with the default', (done)->
      Model = createModel
        name: 'simpleDefault'
        schema:
          properties:
            val:
              type: 'number'
              default: 3

      object = Model.create {}
      assert object
      assert object.doc
      assert object.doc.val == 3
      done()

  describe 'property with array default', ->
    it 'should create the property on the document with the default', (done)->
      schema =
        properties:
          val:
            type: 'array'
            default: [1,2,3]

      Model = createModel
        name: 'simpleDefault'
        schema: schema

      object = Model.create {}
      assert object
      assert object.doc
      each object.doc.val, (v, i)->
        assert schema.properties.val.default[i] == v
      done()

    it 'should create a deep copy of the default', (done)->
      schema =
        properties:
          val:
            type: 'array'
            default: [1,2,3]

      Model = createModel
        name: 'simpleDefault'
        schema: schema

      object = Model.create {}
      object.doc.val.push 4
      assert object
      assert object.doc
      assert object.doc.val.length == 4
      assert schema.properties.val.default.length == 3
      done()

  describe 'property with object default', ->
    it 'should create the property on the document with the default', (done)->
      schema =
        properties:
          val:
            type: 'object'
            default: {a: 3, b: 4, c: 5}

      Model = createModel
        name: 'simpleDefault'
        schema: schema

      object = Model.create {}
      assert object
      assert object.doc
      each object.doc.val, (v, i)->
        assert schema.properties.val.default[i] == v
      done()


    it 'should create a deep copy of the default', (done)->
      schema =
        properties:
          val:
            type: 'object'
            default: {a: 3, b: 4, c: 5}

      Model = createModel
        name: 'simpleDefault'
        schema: schema

      object = Model.create {}
      object.doc.val.d = 6
      assert object
      assert object.doc
      assert Object.keys(object.doc.val).length == 4
      assert Object.keys(schema.properties.val.default).length == 3
      done()

  describe 'nested properties with nested defaults', ->
    it 'should create the nested property with the default', (done)->
      schema =
        properties:
          simple:
            type: 'integer'
            default: 4
          complex:
            type: 'object'
            properties:
              name:
                type: 'string'
                default: 'a complicated thing'
              height:
                type: 'number'
                default: 3.14
              width:
                type: 'number'
                default: -> 6.7
              location:
                type: 'object'
                properties:
                  planet:
                    type: 'string'
                    default: 'mars'
                  continent:
                    type: 'string'
                    default: -> 'asia'

      Model = createModel
        name: 'moreDefaults'
        schema: schema

      object = Model.create {}

      assert object
      assert object.doc
      assert object.doc.simple == schema.properties.simple.default

      assert object.doc.complex.name ==\
        schema.properties.complex.properties.name.default

      assert object.doc.complex.height ==\
        schema.properties.complex.properties.height.default
      assert object.doc.complex.width ==\
        schema.properties.complex.properties.width.default()

      assert object.doc.complex.location.planet ==\
        schema.properties.complex.properties.location.properties.planet.default

      assert object.doc.complex.location.continent ==\
        schema.properties.complex.properties.location.properties.continent.default()

      done()
