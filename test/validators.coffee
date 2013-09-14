assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src/model'


describe 'Validators', ->

  describe 'minimum', ->
    Model = createModel
      name: 'minimumCheck'
      schema:
        properties:
          val:
            type: 'number'
            minimum: 5

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:25
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:1
      assert instance.invalid
      done()


  describe 'exclusive minimum', ->
    Model = createModel
      name: 'exclusiveMinimumCheck'
      schema:
        properties:
          val:
            type: 'number'
            minimum: 5
            exclusiveMinimum: true

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:25
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:5
      assert instance.invalid
      done()


  describe 'maximum', ->
    Model = createModel
      name: 'maximumCheck'
      schema:
        properties:
          val:
            type: 'number'
            maximum: 5

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:1
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:10
      assert instance.invalid
      done()


  describe 'exclusive maximum', ->
    Model = createModel
      name: 'exclusiveMaximumCheck'
      schema:
        properties:
          val:
            type: 'number'
            maximum: 25
            exclusiveMaximum: true

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:20
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:25
      assert instance.invalid
      done()


  describe 'divisibleBy', ->
    Model = createModel
      name: 'divisibleByCheck'
      schema:
        properties:
          val:
            type: 'number'
            divisibleBy: 5

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:10
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:2
      assert instance.invalid
      done()


  describe 'required', ->
    Model = createModel
      name: 'requiredCheck'
      schema:
        properties:
          val:
            type: 'number'
            required: true

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:10
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: foo:2
      assert instance.invalid
      done()


  describe 'pattern', ->
    Model = createModel
      name: 'patternCheck'
      schema:
        properties:
          val:
            type: 'string'
            pattern: /\d\d\d/

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:'123'
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:'abc'
      assert instance.invalid
      done()


  describe 'format', ->
    # NB: we're not checking all of the values in the spec; instead we're just
    # checking one and assuming that the others will work as advertised.
    Model = createModel
      name: 'formatCheck'
      schema:
        properties:
          val:
            type: 'string'
            format: 'ip-address'

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:'127.0.0.1'
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:'abc'
      assert instance.invalid
      done()


  describe 'minLength', ->
    Model = createModel
      name: 'minLengthCheck'
      schema:
        properties:
          val:
            type: 'string'
            minLength: 3

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:'abcdef'
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:'ab'
      assert instance.invalid
      done()


  describe 'maxLength', ->
    Model = createModel
      name: 'maxLengthCheck'
      schema:
        properties:
          val:
            type: 'string'
            maxLength: 4

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:'abc'
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:'abdef'
      assert instance.invalid
      done()


  describe 'minItems', ->
    Model = createModel
      name: 'minItemsCheck'
      schema:
        properties:
          val:
            type: 'array'
            minItems: 3

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:[1,2,3]
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:[4,5]
      assert instance.invalid
      done()


  describe 'maxItems', ->
    Model = createModel
      name: 'maxItemsCheck'
      schema:
        properties:
          val:
            type: 'array'
            maxItems: 4

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:[1,2,3]
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:[1,2,3,4,5]
      assert instance.invalid
      done()


  describe 'uniqueItems', ->
    Model = createModel
      name: 'uniqueItemsCheck'
      schema:
        properties:
          val:
            type: 'array'
            uniqueItems: true

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:[1,2,3]
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:[1,2,3,1]
      assert instance.invalid
      done()


  describe 'enum', ->
    Model = createModel
      name: 'enumCheck'
      schema:
        properties:
          val:
            type: 'string'
            enum: ['eggs', 'ham']

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:'eggs'
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:'spam'
      assert instance.invalid
      done()


  describe 'disallow', ->
    Model = createModel
      name: 'disallowCheck'
      schema:
        properties:
          val:
            type: 'any'
            disallow: ['number', 'date']

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:'eggs'
      assert instance.doc
      assert not instance.invalid
      done()

    it 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:123
      assert instance.invalid

      instance = Model.create doc: val:new Date
      assert instance.invalid

      done()


  describe 'dependencies', ->
    Model = createModel
      name: 'dependenciesCheck'
      schema:
        properties:
          val:
            type: 'object'
            dependencies:
              name: 'f'
              properties:
                a:
                  type: 'string'
                b:
                  type: 'string'


    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:{a:1, b:2}
      assert instance.doc
      assert not instance.invalid
      done()

    it.skip 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:{a:1, b:false}
      console.log instance.invalid, instance.doc
      assert instance.invalid
      done()

  describe 'allOf', ->
    Model = createModel
      name: 'allOfCheck'
      schema:
        properties:
          val:
            allOf: [
              {properties: bar:{type:'integer'}, required: ['bar']}
              {properties: foo:{type:'string'}, required: ['foo']}
              ]

    it 'should validate when valid', (done)->
      assert Model
      instance = Model.create doc: val:{bar:1, foo:'yes'}
      assert instance.doc
      assert not instance.invalid
      done()

    it.skip 'should not validate when invalid', (done)->
      assert Model
      instance = Model.create doc: val:{bar:3}
      #assert instance.invalid
      done()

# no tests in json-schema for these, and like the dependencies validator, haven't
# yet figured these out.

# anyOf
# allOf
# oneOf
# items
