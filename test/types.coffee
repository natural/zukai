assert = require 'assert'
{isEqual} = require 'underscore'
{createModel} = require '../src'


describe 'Types', ->
  describe 'Number', ->
    it 'should be allowed as a field type', ->
      Berry = createModel
        name: 'berry'
        schema:
          properties:
            jinx:
              type: 'number'
              default: 3.1
      a = Berry.create jinx:4.2
      assert a.doc.jinx == 4.2

    it 'should use the default value when not specified', ->
      Berry = createModel
        name: 'berry'
        schema:
          properties:
            jinx:
              type: 'number'
              default: 3.6
      a = Berry.create {}
      assert a.doc.jinx == 3.6

    it 'should use the default function when not specified', ->
      Berry = createModel
        name: 'berry'
        schema:
          properties:
            jinx:
              type: 'number'
              default: ->123.8
      a = Berry.create {}
      assert a.doc.jinx == 123.8


  describe 'String', ->
    it 'should be allowed as a field type', ->
      Dish = createModel
        name: 'dish'
        schema:
          properties:
            kind:
              type: 'string'
              default: 'cup'
      a = Dish.create kind:'plate'
      assert a.doc.kind == 'plate'

    it 'should use the default value when not specified', ->
      Dish = createModel
        name: 'dish'
        schema:
          properties:
            kind:
              type: 'string'
              default: 'cup'
      a = Dish.create {}
      assert a.doc.kind == 'cup'

    it 'should use the default function when not specified', ->
      Dish = createModel
        name: 'dish'
        schema:
          properties:
            kind:
              type: 'string'
              default: ->'plate'
      a = Dish.create {}
      assert a.doc.kind == 'plate'


  describe 'Date', ->
    it 'should be allowed as a field type', ->
      now = new Date
      Fish = createModel
        name: 'fish'
        schema:
          properties:
            born:
              type: 'date'
              default: null
      a = Fish.create born:now
      assert a.doc.born == now

    it 'should use the default value when not specified', ->
      sometime = new Date '1920-03-04'
      Fish = createModel
        name: 'fish'
        schema:
          properties:
            born:
              type: 'date'
              default: sometime
      a = Fish.create {}
      assert a.doc.born == sometime

    it 'should use the default function when not specified', (done)->
      sometime = new Date
      Fish = createModel
        name: 'fish'
        schema:
          properties:
            born:
              type: 'date'
              default: -> new Date

      later = ->
        a = Fish.create {}
        assert a.doc.born.getTime() > sometime.getTime()
        done()
      setTimeout later, 10


  describe 'Array', ->
    it 'should be allowed as a field type', ->
      Honey = createModel
        name: 'honey'
        schema:
          properties:
            hives:
              type: 'array'
              default: []
      a = Honey.create hives:[1,2,3]
      assert a.doc.hives.length == 3

    it 'should use the default value when not specified', ->
      Jam = createModel
        name: 'jam'
        schema:
          properties:
            sizes:
              type: 'array'
              default: [4,5,6,7]
      a = Jam.create {}
      assert isEqual, a.doc.sizes, [4,5,6,7]

    it 'should use the default function when not specified', ->
      Kite = createModel
        name: 'kite'
        schema:
          properties:
            points:
              type: 'array'
              default:->[8,9,10,11,12]
      a = Kite.create {}
      assert isEqual, a.doc.points, [8,9,10,11,12]



  describe 'Boolean', ->
    it 'should be allowed as a field type', ->
      Honey = createModel
        name: 'honey'
        schema:
          properties:
            hives:
              type: 'boolean'
              default: false
      a = Honey.create hives:true
      assert a.doc.hives == true

    it 'should use the default value when not specified', ->
      Jam = createModel
        name: 'jam'
        schema:
          properties:
            sizes:
              type: 'boolean'
              default: true
      a = Jam.create {}
      assert isEqual, a.doc.sizes, true

    it 'should use the default function when not specified', ->
      Kite = createModel
        name: 'kite'
        schema:
          properties:
            points:
              type: 'boolean'
              default:->false
      a = Kite.create {}
      assert isEqual, a.doc.points, false




  describe 'Integer', ->
    it 'should be allowed as a field type', ->
      Berry = createModel
        name: 'berry'
        schema:
          properties:
            jinx:
              type: 'integer'
              default: 3
      a = Berry.create jinx:4
      assert a.doc.jinx == 4

    it 'should use the default value when not specified', ->
      Berry = createModel
        name: 'berry'
        schema:
          properties:
            jinx:
              type: 'integer'
              default: 3
      a = Berry.create {}
      assert a.doc.jinx == 3

    it 'should use the default function when not specified', ->
      Berry = createModel
        name: 'berry'
        schema:
          properties:
            jinx:
              type: 'integer'
              default: ->123
      a = Berry.create {}
      assert a.doc.jinx == 123



  describe 'Object', ->
    it 'should be allowed as a field type', ->
      Berry = createModel
        name: 'berry'
        schema:
          properties:
            jinx:
              type: 'object'
              default: {}
      a = Berry.create jinx:{}
      assert isEqual, a.doc.jinx, {}

    it 'should use the default value when not specified', ->
      Berry = createModel
        name: 'berry'
        schema:
          properties:
            jinx:
              type: 'object'
              default: {a:1}
      a = Berry.create {}
      assert isEqual, a.doc.jinx, {a:1}

    it 'should use the default function when not specified', ->
      Berry = createModel
        name: 'berry'
        schema:
          properties:
            jinx:
              type: 'object'
              default: ->{b:2}
      a = Berry.create {}
      assert isEqual, a.doc.jinx, {b:2}






  describe 'Null', ->
    it 'should be allowed as a field type', ->
      Berry = createModel
        name: 'berry'
        schema:
          properties:
            jinx:
              type: 'null'
              default: null
      a = Berry.create jinx:null
      assert a.doc.jinx == null

    it 'should use the default value when not specified', ->
      Berry = createModel
        name: 'berry'
        schema:
          properties:
            jinx:
              type: 'null'
              default: null
      a = Berry.create {}
      assert a.doc.jinx == null

    it 'should use the default function when not specified', ->
      Berry = createModel
        name: 'berry'
        schema:
          properties:
            jinx:
              type: 'null'
              default: ->null
      a = Berry.create {}
      assert a.doc.jinx == null
