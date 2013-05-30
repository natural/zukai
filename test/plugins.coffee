assert = require 'assert'
{createModel} = require '../src'



describe 'Plugins', ->
  before (done)->
    done()

  describe 'basic interface', ->
    it 'should allow plugin installation', (done)->
      Car = createModel name: 'Car'
      Car.plugin (model, options)->
        assert model is Car
        done()

    it 'should allow chained installation', (done)->
      Truck = createModel name: 'Truck'
      features = []

      towPackage = ->
        features.push 'tow'

      airBrakes = ->
        assert features.length
        done()

      Truck.plugin(towPackage).plugin(airBrakes)
