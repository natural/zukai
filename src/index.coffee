{EventEmitter} = require 'events'
{extend} = require 'underscore'
{defer} = require 'q'

async = require 'async'
inflection = require 'inflection'
jsonschema = require 'jsonschema'


exports.createModel = (defn)->
  defn = defn or {}
  name = defn.name

  if not name
    throw new TypeError 'Model name required'

  bucket = defn.bucket
  bucket = inflection.pluralize name.toLowerCase() if not bucket

  options =
    name: name
    connection: defn.connection or null
    schema: defn.schema or {}
    bucket: bucket
    hooks:
      pre:  {create:[], save:[], del:[]}
      post: {create:[], save:[], del:[]}

  derived = extend (new EventEmitter()),
    exports.ProtoModel,
    (defn.methods or {}),
    options

  derived.registry[bucket] = derived


exports.ProtoModel =
  name: 'ProtoModel'
  connection: null
  bucket: 'undefined'
  indexes: []
  registry: {}

  create: (key, doc)->
    self = @
    if (typeof key) == 'object'
      doc = key
      key = null

    inst = extend {}, self, key: key, doc: doc, links: [], reply: {}
    self.setDefaults self.schema, inst.doc

    for hook in inst.hooks.pre.create
      hook inst

    res = jsonschema.validate inst.doc, self.schema
    if res.errors and res.errors.length
      extend inst, invalid: res, doc: {}
    else
      inst.invalid = false
      for hook in inst.hooks.post.create
        hook inst
      self.emit 'create', inst
    inst

  get: (key)->
    self = @
    deferred = defer()

    if not self.connection
      deferred.reject message: 'Not connected'
      return deferred.promise

    self.connection.get bucket: self.bucket, key: key, (reply)->
      if reply and reply.errmsg
        deferred.reject message: reply.errmsg
      else if reply and reply.content
        objects = for result in reply.content
          inst = self.create key, JSON.parse result.value
          extend inst, links: result.links, reply: reply, key: key
        objects = objects[0] if objects.length == 1
        deferred.resolve objects
      else
        deferred.resolve null
    return deferred.promise

  del: ->
    self = @
    deferred = defer()

    if not self.connection
      deferred.reject message: 'Not connected'
      return deferred.promise

    if not self.key
      deferred.reject message: 'No key'
      return deferred.promise

    hooks = self.getHooks 'pre', 'del'
    run = (hook, cb)->
      hook self, (err)->
        cb err, self
    async.each hooks, run, (err, results)->
      if err
        deferred.reject message: err
        return deferred.promise
      self.connection.del bucket: self.bucket, key: self.key, (reply)->
        if reply.errmsg
          deferred.reject message: reply.errmsg
        else
          self.deleted = true
          hooks = self.getHooks 'post', 'del'
          run = (hook, cb)->
            hook self, (err)->
              cb err, self
          async.each hooks, run, (err)->
            self.emit 'delete', self
            if err
              deferred.reject message: err
            else
              deferred.resolve null
    deferred.promise


  put: (options, callback)->
    self = @
    deferred = defer()

    if not self.connection
      deferred.reject message: 'Not connected'
      return deferred.promise

    if typeof options == 'function'
      callback = options

    res = jsonschema.validate self.doc, self.schema

    if res.errors and res.errors.length
      self.invalid = res
      deferred.reject message: 'Invalid'
      return deferred.promise

    hooks = self.getHooks 'pre', 'save'
    run = (hook, cb)->
      hook self, (err)->
        cb err, self
    async.each hooks, run, (err, results)->
      if err
        return deferred.reject message: err

      request =
        bucket: self.bucket
        return_body: true
        content:
          value: JSON.stringify self.doc
          content_type: 'application/json'
          indexes: self.indexes
          links: self.links

      request.key = self.key if self.key?
      request.vclock = self.reply?vclock if self.reply?vclock?

      self.connection.put request, (reply)->
        if reply.errmsg
          return deferred.reject message: errmsg

        self.key = reply.key if reply.key
        self.reply = reply

        hooks = self.getHooks 'post', 'save'
        run = (hook, cb)->
          hook self, (err)->
            cb err, self

        async.each hooks, run, (err, results)->
          if err
            self.invalid = true
            deferred.reject message: err
          else
            self.invalid = false
            self.emit 'save', self
            deferred.resolve self

    deferred.promise

  toJSON: ->
    @doc

  plugin: (plugin, options)->
    plugin @, options

  pre: (kwd, callable)->
    if not @hooks.pre[kwd]?
      throw new Error "Model does not support pre #{kwd}"
    @hooks.pre[kwd].push callable

  post: (kwd, callable)->
    if not @hooks.post[kwd]?
      throw new Error "Model does not support post #{kwd}"
    @hooks.post[kwd].push callable

  getHooks: (type, kwd)->
    hooks = @hooks[type][kwd]
    if not hooks.length
      hooks = [(o, n)-> n()]
    hooks

  relate: (tag, obj, dupes=false)->
    relation = tag:tag, key:obj.key, bucket:obj.bucket
    insert = true

    if not dupes
      for item in @links when item.tag==tag
        if item.key == obj.key and item.bucket==obj.bucket
          insert = false

    if insert
      @links.push relation

  resolve: (tag, callback)->
    self = @
    links = (link for link in self.links when link.tag==tag)

    if not links.length
      return callback null, null

    models = {}
    for name, model of self.registry
      models[model.bucket] = model

    fetch = (link, cb)->
      model = models[link.bucket]
      if model
        model.get(link.key).then (doc)->
          cb null, doc # wrong
      else
        cb message: "No model registered for #{link.bucket}"

    async.map links, fetch, callback

  setDefaults: (schema, doc)->
    for name, prop of schema.properties
      if not doc[name]?
        def = @getDefault prop
        doc[name] = def if def isnt undefined
        if prop.properties
          @setDefaults prop, doc[name]

  getDefault: (property)->
    val = property.default
    switch typeof val
      when 'function'
        val = val()
    val


# For reference, a reply object from riakpbc looks like this:
#
# { content:
#    [ { value: '{"e":5,"f":6}',
#        content_type: 'application/json',
#        vtag: '58VwhV1xnOUOKl8VjT1Uj3',
#        links: [Object],
#        last_mod: 1369679311,
#        last_mod_usecs: 898272 } ],
#   vclock: <Buffer 6b ce ... 2c 00> }
#
