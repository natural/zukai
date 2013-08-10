assert = require 'assert'
{createClient} = require 'riakpbc'
{createCounterModel, ProtoCounter} = require '../src'

Model = instance = connection = null


describe 'Counter Model', ->
  before (done)->
    connection = createClient()
    done()

  describe 'constructor', ->
    it 'should require a name', ->
      try
        createCounterModel()
        assert 0
      catch err
        assert err.message == 'Model name required'

    it 'should work with only a name', ->
      Foo = createCounterModel name:'foo'
      assert Foo.name == 'foo'

      Bar = createCounterModel 'bar'
      Bar.name == 'bar'

    it 'should register the counter model', ->
      'foo' in ProtoCounter.registry

  describe 'static methods', ->
    it 'should have a known static method', ->
      Bar = createCounterModel name:'bar'
      assert Bar.create?

    it 'should have a specified static method', ->
      Other = createCounterModel
        name: 'other'
        foo: ->
      assert Other.foo

    it 'should have a specified static with correct `this`', ->
      Other = createCounterModel
        name: 'other'
        foo: ->
          @
      assert Other.foo() == Other

  describe 'model instance', ->
    it 'should have a known method', ->
      Some = createCounterModel
        name: 'Some'
      x = Some.create {}
      assert x.put

    it 'should have a specified method', ->
      Again = createCounterModel
        name: 'Again'
        check: ->
      x = Again.create {}
      assert x.check

    it 'should have a specified method with correct `this`', ->
      More = createCounterModel
        name: 'More'
        yup: ->
          @
      x = More.create {}
      assert x.yup() == x

    it 'should have a method that can access the class', ->
      Bore = createCounterModel
        name: 'Bore'
        check: ->
          true
      x = Bore.create {}
      assert x.check()

    it 'should provide a default bucket name', ->
      Score = createCounterModel
        name: 'score'
      assert Score.bucket == 'scores'

    it 'should allow a provided bucket name', ->
      bucket = 'the_doors_suck'
      Door = createCounterModel
        name: 'door'
        bucket: bucket
      assert Door.bucket == bucket

  describe 'saving counter model objects', ->
    it 'should indicate an error when connection is missing', (done)->
      Core = createCounterModel
        name: 'core'
        bucket: 'core-counters'

      c = Core.create name:'coar'
      assert c
      c.put({}).catch (err)->
        assert err
        done()

    it 'should work when connection is present', (done)->
      assert connection
      Lore = createCounterModel
        name: 'lore'
        connection: connection
        bucket: 'lore-counters'

      connection.setBucket {bucket: Lore.bucket, props: {allow_mult: true}}, ->

      c = Lore.create key: 'counter-lore', value: 1

      ok = (obj, err)->
        assert obj
        assert obj.doc.value == 1
        c.del().then ->
          cc = Lore.create key: 'xyz', value: 1
          cc.put().then (doc)->
            assert doc.key == 'xyz'
            cc.del().then done

      c.put().then(ok).catch (err)->
        console.log 'something errored', err
        done()

  describe 'working with model objects by key', ->
    it 'should allow Model.get', (done)->
      Model = createCounterModel
        name: 'gore'
        connection: connection
        bucket: 'gore-counters'

      instance = Model.create 'goar-counter', value: 3
      connection.setBucket {bucket: Model.bucket, props: {allow_mult: true}}, ->

      ok = (inst)->
        Model.get(inst.key).then (obj)->
          obj.doc.value == 3
          inst.del().then done

      err = ->
        console.log 'some error', arguments

      instance.put().then(ok).catch(err)

  describe 'model() method', ->
    it 'should support retrieving models by name', (done)->
      Model = createCounterModel name: 'Named', bucket: 'named-bucket'

      assert Model
      assert Model == Model.model 'Named'
      assert Model == Model.model 'named-bucket'

      assert not Model.model 'any-other-thing'

      done()
