assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src/model'

connection = null


describe 'Creating Model', ->
  before (done)->
    connection = createClient()
    done()

  describe 'createModel factory function', ->
    it 'should require a name', ->
      try
        createModel()
        assert 0
      catch err
        assert err.message == 'Model name required'

      A = createModel name: 'A'
      assert A.name == 'A'

    it 'should derive a bucket name when not supplied', ->
      B = createModel name: 'Empty'
      assert B.bucket == 'empties'

    it 'should accept a bucket name when supplied', ->
      C = createModel name: 'C', bucket: 'X'
      assert C.bucket == 'X'

    it 'should create a model with a static .get method', ->
      D = createModel name: 'D'
      assert D.get

    it 'should create a model without a static .put method', ->
      E = createModel name: 'E'
      assert not E.put

    it 'should create a model a static .del method', ->
      F = createModel name: 'F'
      assert F.del

    it 'should accept a connection', ->
      G = createModel name: 'G', connection: connection
      assert G.connection == connection

    it 'should create a model with .create method', ->
      H = createModel name: 'H'
      assert H.create
