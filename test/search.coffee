assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src'


Model = null


describe 'Search', ->
  before (done)->
    Model = createModel
      name: 'searchcheck'
      connection: createClient()
      schema:
        properties:
          name:
            type: 'string'
          age:
            type: 'number'
    done()


  describe 'basic query', ->
    it.skip 'should return expected results', (done)->
      alice = Model.create name:'alice', age:21
      assert alice.doc.name == 'alice'

      alice.save (err, inst1)->
        assert inst1

        bob = Model.create name:'bob', age:34
        assert bob.doc.name == 'bob'

        bob.save (err, inst2)->
          assert inst2

          Model.search name:'bob', (err, cursor)->
            assert not err
            cursor.toArray (err, res)->
              assert res.length == 1
              done()
