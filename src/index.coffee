{EventEmitter} = require 'events'
{clone, extend} = require 'underscore'

async = require 'async'
inflection = require 'inflection'
jsonschema = require 'jsonschema'


exports.createModel = createModel = (defn)->
  defn = defn or {}
  name = defn.name

  if not name
    throw new TypeError 'Schema name required'

  bucket = defn.bucket
  bucket = inflection.pluralize name.toLowerCase() if not bucket

  options =
    name: name
    connection: defn.connection or null
    schema: defn.schema or {}
    bucket: bucket
    plugins:
      pre: {init:[], save:[], del:[]}
      post: {init:[], save:[], del:[]}

  derived = extend new EventEmitter(), ProtoModel, options

  for key, value of (defn.methods or {})
    derived[key] = value

  derived.registry[bucket] = derived
  derived




exports.ProtoModel = ProtoModel =
  name: 'ProtoModel'
  connection: null
  bucket: 'undefined'
  indexes: []
  links: []
  registry: {}

  create: (key, doc)->
    if (typeof key) == 'object'
      doc = key
      key = null
    inst = extend {}, @, {key:key, doc:doc}
    @setDefaults @schema, inst.doc
    res = jsonschema.validate inst.doc, @schema
    if res.errors.length
      inst.invalid = res
      inst.doc = {}
    else
      inst.invalid = false
      @emit 'create', inst
    inst

  get: (key, callback)->
    self = @
    con = @connection
    if not con
      return callback errmsg:'not connected'
    @connection.get bucket:@bucket, key:key, (reply)->
      if reply and reply.content and reply.content[0]
        inst = self.create JSON.parse reply.content[0].value, reply
        inst.reply = reply
        inst.key = key
      else
        inst = null
      callback null, inst

  del: (callback)->
    con = @connection
    if not con
      return callback errmsg:'not connected'
    self = @
    if not self.key
      return callback errmsg:'no key'
    self.emit 'delete', self
    con.del bucket:self.bucket, key:self.key, (reply)->
      self.deleted = true
      callback null, reply

  save: (options, callback)->
    if typeof options == 'function'
      callback = options
    self = @
    con = @connection
    if not con
      return callback errmsg:'not connected'

    res = jsonschema.validate @doc, @schema

    if res.errors.length
      @invalid = res
      return callback errmsg:'invalid'
    else
      @invalid = false

    before = for plugin in self.plugins.pre.save
      do(plugin)->
        (cb)->
          plugin (err)->
            if err
              throw new Error err
            cb()

    async.series before, (err, results)->
      #console.log 'before ran all', err, results

    op = if self.key then 'update' else 'insert'

    content =
      value: JSON.stringify self.doc
      content_type: 'application/json'
      indexes: self.indexes
      links: self.links

    request =
      bucket: self.bucket
      content: content
      return_body: true

    if self.key
      request.key = self.key

    if self.vclock?
      request.vclock = self.vclock

    self.connection.put request, (reply)->
      #console.log 'saved', reply
      self.key = reply.key
      self.emit op, self

      after = for plugin in self.plugins.post.save
        do(plugin)->
          (cb)->
            plugin (err)->
              cb err, self

      async.series after, (err, results)->
        #callback null, self

      # weak:
      callback null, self

  toJSON: ->
    @doc

  plugin: (plugin, options)->
    plugin @, options

  pre: (kwd, callable)->
    if not @plugins.pre[kwd]?
      throw new Error "Schema does not support pre #{kwd}"
    @plugins.pre[kwd].push callable

  post: (kwd, callable)->
    if not @plugins.post[kwd]?
      throw new Error "Schema does not support post #{kwd}"
    @plugins.post[kwd].push callable

  relate: (tag, obj)->
    relation = tag:tag, key:obj.key, bucket:obj.bucket
    @links.push relation

  resolve: (tag, callback)->
    self = @
    links = (link for link in self.links when link.tag==tag)

    if not links.length
      return callback null, links

    fetch = for link in links
      do(link)->
        (cb)->
          for name, model of self.registry
            if model.bucket == link.bucket
              model.get link.key, (err, obj)->
                cb null, obj

    async.parallel fetch, (err, results)->
      callback err, results


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
      #when 'object'
      #  val = clone val
    val
