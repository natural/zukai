assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel, ProtoModel} = require '../src'

Model = instance = connection = null


describe 'Model', ->
  before (done)->
    connection = createClient()
    done()

  describe 'constructor', ->
    it 'should require a name', ->
      try
        createModel()
        assert 0
      catch err
        assert err.message == 'Schema name required'

    it 'should work with only a name', ->
      Foo = createModel name:'foo'
      assert Foo.name == 'foo'

    it 'should register the model', ->
      'foo' in ProtoModel.registry

  describe 'static methods', ->
    it 'should have a known static method', ->
      Bar = createModel name:'bar'
      assert Bar.create?

    it 'should have a specified static method', ->
      Other = createModel
        name: 'other'
        methods:
          foo: ->
      assert Other.foo

    it 'should have a specified static with correct `this`', ->
      Other = createModel
        name: 'other'
        methods:
          foo: ->
            @
      assert Other.foo() == Other

  describe 'model instance', ->
    it 'should have a known method', ->
      Some = createModel
        name: 'Some'
      x = Some.create {}
      assert x.save

    it 'should have a specified method', ->
      Again = createModel
        name: 'Again'
        methods:
          check: ->
      x = Again.create {}
      assert x.check

    it 'should have a specified method with correct `this`', ->
      More = createModel
        name: 'More'
        methods:
          yup: ->
            @
      x = More.create {}
      assert x.yup() == x

    it 'should have a method that can access the class', ->
      Bore = createModel
        name: 'Bore'
        methods:
          check: ->
            true
      x = Bore.create {}
      assert x.check()


    it 'should provide a default bucket name', ->
      Score = createModel
        name: 'score'
      assert Score.bucket == 'scores'

    it 'should allow a provided bucket name', ->
      bucket = 'the_doors_suck'
      Door = createModel
        name: 'door'
        bucket: bucket
      assert Door.bucket == bucket


  describe 'saving model objects', ->
    it 'should indicate an error when connection is missing', (done)->
      Core = createModel
        name: 'core'
        schema:
          properties:
            name:
              type: 'string'
      c = Core.create name:'coar'
      assert c
      c.save {}, (err, doc)->
        assert err
        assert not doc
        done()

    it 'should work when connection is present', (done)->
      assert connection
      Lore = createModel
        name: 'lore'
        connection: connection
        schema:
          properties:
            name:
              type: 'string'
      c = Lore.create name:'loar'
      c.save {}, (err, doc)->
        assert not err
        assert doc
        done()

  describe 'working with model objects by key', ->
    it 'should allow Model.get', (done)->
      Model = createModel
        name: 'gore'
        connection: connection
        schema:
          properties:
            name:
              type: 'string'

      instance = Model.create name:'goar'
      instance.save (err, inst)->
        assert not err
        assert inst
        Model.get inst.key, (err, doc)->
          assert not err
          assert doc
          assert doc.doc.name == 'goar'
          done()

    it 'should allow instance.del', (done)->
      instance.del (err, msg)->
        assert not err
        Model.get instance.key, (err, doc)->
          assert not err
          if doc
            assert doc.deleted == 1
          done()
