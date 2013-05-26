assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src'


Model = null
connection = null


badgePlugin = (model, options)->
  model.schema.properties.badge =
    type: 'string'



describe 'Plugins', ->
  beforeEach (done)->
    Model = createModel
      name: 'pluginscheck'
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

  describe 'plugin events', ->
    it 'pre-save should work', (done)->
      Model.plugin (model, options)->
        model.pre 'save', (next)->
          next()
          done()
      m = Model.create name:'x', age:12
      m.save ->

    it 'pre-save should propagate errors', (done)->
      Model.plugin (model, options)->
        model.pre 'save', (next)->
          next 'fail'
      m = Model.create name:'x', age:12
      try
          m.save ->
          assert 0
      catch err
          done()

    it 'post-save should work', (done)->
      Model.plugin (model, options)->
        model.post 'save', (next)->
          next()
          done()
      m = Model.create name:'x', age:12
      m.save ->

    it 'post-save should propagate errors', (done)->
      Model.plugin (model, options)->
        model.post 'save', (next)->
          next 'fail'
      m = Model.create name:'x', age:12
      m.save (err)->
        done()
