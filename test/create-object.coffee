assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src/model'


connection = null


describe 'Creating Model Objects', ->
  before (done)->
    connection = createClient()
    done()

  describe 'object buckets', ->
    it 'should match model buckets', ->
      A = createModel name: 'A'
      assert A.bucket == 'as'
      a = A.create {}
      assert a.bucket == 'as'

  describe 'object static methods', ->
    it 'should not have a static .get method', ->
      B0 = createModel name: 'B0'
      assert B0.get
      b = B0.create {}
      assert not b.get

    it 'should have an instance .put method', ->
      B1 = createModel name: 'B1'
      assert B1.get
      b = B1.create {}
      assert b.put

    it 'should have an instance .del method', ->
      B2 = createModel name: 'B2'
      assert B2.get
      b = B2.create {}
      assert b.del

  describe 'create object method', ->
    it 'should create a new model instance', ->
      C0 = createModel name: 'C'
      assert C0.create
      c = C0.create {}
      assert c.constructor == C0

    it 'should provide an empty .key property', ->
      C1 = createModel name: 'C'
      c1 = C1.create {}
      assert c1.key == null

    it 'should set .key property when supplied', ->
      C2 = createModel name: 'C'
      c2 = C2.create key: 'yes'
      assert c2.key == 'yes'

  describe 'model and object buckets', ->
    it 'should have instances with .bucket property', ->
      D = createModel name: 'D'
      assert D.create
      d = D.create {}
      assert d.bucket == D.bucket

    it 'should allow changing model bucket', ->
      E = createModel name: 'E'
      e = E.create {}
      assert e.bucket == E.bucket
      E.bucket = 'different'
      assert e.bucket != E.bucket
      assert e.bucket == 'es'
      e.bucket = 'es0'
      assert e.bucket == 'es0'
      assert E.bucket == 'different'

  describe 'model and object connections', ->
    it 'should have instances with .connection property', ->
      F = createModel name: 'F', connection: connection
      f = F.create {}
      assert f.connection == connection
