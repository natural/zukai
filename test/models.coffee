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
        assert err.message == 'Model name required'

    it 'should work with only a name', ->
      Foo = createModel name:'foo'
      assert Foo.name == 'foo'

      Bar = createModel 'bar'
      Bar.name == 'bar'

    it 'should register the model', ->
      'foo' in ProtoModel.registry

  describe 'static methods', ->
    it 'should have a known static method', ->
      Bar = createModel name:'bar'
      assert Bar.create?

    it 'should have a specified static method', ->
      Other = createModel
        name: 'other'
        foo: ->
      assert Other.foo

    it 'should have a specified static with correct `this`', ->
      Other = createModel
        name: 'other'
        foo: ->
          @
      assert Other.foo() == Other

  describe 'model instance', ->
    it 'should have a known method', ->
      Some = createModel
        name: 'Some'
      x = Some.create {}
      assert x.put

    it 'should have a specified method', ->
      Again = createModel
        name: 'Again'
        check: ->
      x = Again.create {}
      assert x.check

    it 'should have a specified method with correct `this`', ->
      More = createModel
        name: 'More'
        yup: ->
          @
      x = More.create {}
      assert x.yup() == x

    it 'should have a method that can access the class', ->
      Bore = createModel
        name: 'Bore'
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
      c.put({}).catch (err)->
        assert err
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
      c.put().then (doc)->
        assert doc
        c.del().then ->
          cc = Lore.create key:'xyz', name:'boar'
          cc.put().then (doc)->
            assert doc.key == 'xyz'
            cc.del().then done


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
      instance.put().then (inst)->
        assert inst
        Model.get(inst.key).then (doc)->
          assert doc
          assert doc.doc.name == 'goar'
          Model.get(key:inst.key).then ->
            doc.del().then done

    it 'should allow instance.del', (done)->
      instance.del().then ->
        Model.get(instance.key).then (doc)->
          done()

  describe 'options to .get()', ->
    it 'should support head:true', (done)->
      Model = createModel
        name: 'gore'
        connection: connection
        schema:
          properties:
            name:
              type: 'string'
              required: true

      key = 'known-key'
      instance = Model.create key, name:'algorithm'
      instance.put().then ->
        instance.get(key, {head:1}).then (obj)->
          assert obj.key == key
          assert Object.keys(obj.doc).length == 0
          assert obj.reply.content[0].value == ''
          instance.del().then done

  describe 'options to .put()', ->
    it 'should support return_body:true', (done)->
      Model = createModel
        name: 'gore'
        connection: connection
        schema:
          properties:
            name:
              type: 'string'
              required: true

      key = 'another-key'
      instance = Model.create key, name:'other'
      instance.put(return_body:true).then (obj)->
        assert obj.reply.content[0].value.length > 0
        instance.del().then done

    it 'should support return_head:true', (done)->
      Model = createModel
        name: 'gore'
        connection: connection
        schema:
          properties:
            name:
              type: 'string'
              required: true

      key = 'yet-another-key'
      instance = Model.create key, name:'other'
      instance.put(return_head:true).then (obj)->
        assert obj.reply.content[0].value.length == 0
        assert obj.reply.content[0].value == ''
        instance.del().then done

  describe.skip 'options to .del()', ->
    it 'should support something', (done)->
      Model = createModel
        name: 'gore'
        connection: connection
        schema:
          properties:
            name:
              type: 'string'
              required: true

      key = 'even-yet-another-key'
      instance = Model.create key, name:'other'
      instance.put(return_body:true).then (obj)->
        instance.del().then ->
          done()
