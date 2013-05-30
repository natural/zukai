{defaults} = require 'underscore'


exports.plugins =

  relation: (model, options)->
    options = defaults options, minimum: 0, maximum: options.minimum
    min = options.minimum
    max = options.maximum
    tag = options.tag
    rel = options.model

    if min > max
      throw new Error 'Minimum cannot be greater than maximum'

    model.pre 'put', (object, next)->
      buckets = (b for b, m of model.registry when m.name==rel)

      if not buckets.length
        next new Error "No model #{rel}"

      bucket = buckets[0]
      links = (k for k in object.links when k.bucket==bucket and k.tag==tag)

      if min and links.length < min
        next new Error "Too few relations for #{rel}:#{tag}"
      else if max and links.length > max
        next new Error "Too many relations for #{rel}:#{tag}"
      else
        next()
