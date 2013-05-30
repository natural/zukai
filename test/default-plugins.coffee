assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src'
{plugins} = require '../src/plugins'

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
    it 'should allow missing relationship when minimum=0', (done)->
      Author.plugin plugins.relation,
        model: 'Place'
        tag: 'birth-place'
        minimum: 0

      fitzgerald = Author.create 'f-scott', born:1896
      fitzgerald.put().then fitzgerald.del done

    it 'should not allow missing relationship when minimum=1', (done)->
      Author.plugin plugins.relation,
        model: 'Place'
        tag: 'birth-place'
        minimum: 1

      oakpark = Place.create 'oak-park'
      hemingway = Author.create 'ernest', born:1899

      hemingway.put().catch ->
        hemingway.relate 'birth-place', oakpark
        hemingway.put().then hemingway.del done


    it 'should not allow more than given maximum relationships', (done)->
      Author.plugin plugins.relation,
        model: 'Book'
        tag: 'advanced-payment'
        maximum: 2

      faulkner = Author.create 'will', born:1897
      faulkner.relate 'advanced-payment', Book.create 'mosquitoes'
      faulkner.relate 'advanced-payment', Book.create 'sanctuary'
      faulkner.relate 'advanced-payment', Book.create 'pylon'

      faulkner.put().catch (err)->
        faulkner.links.pop()
        faulkner.put().then faulkner.del done
