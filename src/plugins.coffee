{defaults} = require 'underscore'


exports.plugins =

  relation: (model, options)->
    options = defaults options, minItems: 0, maxItems: options.minItems
    minItems = options.minItems
    maxItems = options.maxItems
    tag = options.tag
    type = options.type

    if not type
      throw new Error 'Missing type'

    if minItems > maxItems
      throw new Error 'minItems cannot be greater than maxItems'

    model.pre 'put', (object, next)->
      buckets = (b for b, m of model.registry when m.name==type)

      if not buckets.length
        return next new Error "No model #{type}"

      bucket = buckets[0]
      links = (k for k in (object.links or []) when k.bucket==bucket and k.tag==tag)

      if minItems and links.length < minItems
        next new Error "Too few relations for #{type}:#{tag}"
      else if maxItems and links.length > maxItems
        next new Error "Too many relations for #{type}:#{tag}"
      else
        next()
