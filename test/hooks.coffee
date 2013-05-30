assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src'


Model = null
connection = null


badgePlugin = (model, options)->
  model.schema.properties.badge =
    type: 'string'



describe 'Hooks', ->
  beforeEach (done)->
    Model = createModel
      name: 'plugins-test'
      connection: createClient()
      schema:
        properties:
          name:
            type: 'string'
          age:
            type: 'number'
    done()

  describe 'basic plugin', ->
    it 'should add schema items', (done)->
      Model.plugin badgePlugin, {k:1, v:2}
      assert Model.schema.properties.badge
      done()

  describe 'plugin put events', ->
    it 'pre-put should work', (done)->
      Model.plugin (model, options)->
        model.pre 'put', (object, next)->
          assert object.doc.name == 'carol'
          next()
          done()
      m = Model.create 'pre-put', name:'carol', age:77
      m.put().then ->
        m.del().then()

    it 'pre-put should propagate errors', (done)->
      Model.plugin (model, options)->
        model.pre 'put', (object, next)->
          next 'fail'
      m = Model.create 'pre-put-error', name:'dave', age:88
      m.put().catch (err)->
        assert err.message == 'fail'
        done()

    it 'post-put should work', (done)->
      Model.plugin (model, options)->
        model.post 'put', (object, next)->
          assert object.doc.name == 'ed'
          next()
          done()
      m = Model.create 'post-put', name:'ed', age:99
      m.put().then ->
        m.del().then()

    it 'post-put should propagate errors', (done)->
      Model.plugin (model, options)->
        model.post 'put', (object, next)->
          next 'fail'
      m = Model.create 'post-put-error', name:'frank', age:101
      m.put().catch (err)->
        assert err.message == 'fail'
        m.del().then done


  describe 'plugin delete events', ->
    it 'pre-delete should work', (done)->
      Model.plugin (model, options)->
        model.pre 'del', (object, next)->
          assert object.doc.name == 'gene'
          next()
          done()
      m = Model.create 'pre-del', name:'gene', age:22
      m.put().then ->
        m.del().then()

    it 'pre-delete should propagate errors', (done)->
      Model.plugin (model, options)->
        model.pre 'del', (object, next)->
          next 'fail'
      m = Model.create 'pre-del-error', name:'harry', age:33
      m.put().then ->
        ok = ->
          assert 0
        er = (err)->
          assert err.message == 'fail'
          Model.hooks.pre.del = []
          m.del().then done
        m.del().then ok, er

    it 'post-delete should work', (done)->
      Model.plugin (model, options)->
        model.post 'del', (object, next)->
          assert object.doc.name == 'iris'
          next()
          done()
      m = Model.create 'post-del', name:'iris', age:44
      m.put().then ->
        m.del().then()

    it 'post-delete should propagate errors', (done)->
      Model.plugin (model, options)->
        model.post 'del', (object, next)->
          next 'fail'
      m = Model.create 'post-del-error', name:'james', age:55
      m.put().then ->
        ok = ->
          assert 0
        er = (err)->
          assert err.message == 'fail'
          Model.hooks.post.del = []
          m.del().then done
        m.del().then ok, er


  describe 'plugin create events', ->
    it 'pre-create should work', (done)->
      Model.plugin (model, options)->
        model.pre 'create', (object, next)->
          assert object.doc.name == 'kate'
          #next()
          done()
      m = Model.create 'pre-create', name:'kate', age:66
      assert m.doc.name == 'kate'

    it 'pre-create should propagate errors', (done)->
      Model.plugin (model, options)->
        model.pre 'create', (object)->
          throw new Error
      try
        m = Model.create 'pre-create-error', name:'larry', age:77
      catch err
        done()

    it 'post-create should work', (done)->
      Model.plugin (model, options)->
        model.post 'create', (object)->
          assert object.doc.name == 'moe'
          object.doc.name = 'mose'
      m = Model.create 'post-create', name:'moe', age:88
      assert m.doc.name == 'mose'
      done()

    it 'post-create should propagate errors', (done)->
      Model.plugin (model, options)->
        model.post 'create', (object)->
          throw new Error
      try
        m = Model.create 'post-create-error', name:'ned', age:99
      catch err
        done()
