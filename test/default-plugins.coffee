assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel, plugins} = require '../src'


Place = Author = Book = Cover = null
connection = null


describe 'Default Plugins', ->
  beforeEach (done)->
    Place = createModel
      name: 'Place'

    Author = createModel
      name: 'Author'
      connection: createClient()

    Book = createModel
      name: 'Book'
      connection: createClient()

    Cover = createModel
      name: 'Cover'
      connection: createClient()

    done()

  describe 'relation', ->
    it 'should allow missing relationship when minItems=0', (done)->
      Author.plugin plugins.relation,
        type: 'Place'
        tag: 'birth-place'
        minItems: 0

      fitzgerald = Author.create 'f-scott', born:1896
      fitzgerald.put().then fitzgerald.del done

    it 'should not allow missing relationship when minItems=1', (done)->
      Author.plugin plugins.relation,
        type: 'Place'
        tag: 'birth-place'
        minItems: 1

      oakpark = Place.create 'oak-park'
      hemingway = Author.create 'ernest', born:1899

      hemingway.put().catch ->
        hemingway.relate 'birth-place', oakpark
        hemingway.put().then hemingway.del done


    it 'should not allow more than given maxItems relationships', (done)->
      Author.plugin plugins.relation,
        type: 'Book'
        tag: 'advanced-payment'
        maxItems: 2

      faulkner = Author.create 'will', born:1897
      faulkner.relate 'advanced-payment', Book.create 'mosquitoes'
      faulkner.relate 'advanced-payment', Book.create 'sanctuary'
      faulkner.relate 'advanced-payment', Book.create 'pylon'

      faulkner.put().catch (err)->
        assert err.message+'' == 'Error: Too many relations for Book:advanced-payment'
        faulkner.links.pop()
        faulkner.put().then faulkner.del done

    it 'should not allow relations to missing models', (done)->
      Author.plugin plugins.relation,
        type: 'Rocket'
        tag: 'ship'

      a = Author.create 'heinlein'
      a.relate 'ship', {}
      a.put().catch (err)->
        assert "#{err.message}" == 'Error: No model Rocket'
        done()


    it 'should not allow relations to undefined models', (done)->
      try
        Author.plugin plugins.relation, tag:'nope'
      catch err
        assert "#{err.message}" == 'Missing type'
      done()
