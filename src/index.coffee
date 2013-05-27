{EventEmitter} = require 'events'
{clone, extend} = require 'underscore'

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
    plugins:
      pre:  {create:[], save:[], del:[]}
      post: {create:[], save:[], del:[]}

  derived = extend new EventEmitter(), exports.ProtoModel, options

  for key, value of (defn.methods or {})
    derived[key] = value

  # returns derived
  derived.registry[bucket] = derived


exports.ProtoModel =
  name: 'ProtoModel'
  connection: null
  bucket: 'undefined'
  indexes: []
  registry: {}

  create: (key, doc)->
    if (typeof key) == 'object'
      doc = key
      key = null
    inst = extend {}, @, {key:key, doc:doc}
    inst.links = []
    @setDefaults @schema, inst.doc

    # run pre-create plugins after defaults have been applied
    # but before validation
    stop = false
    preCreate = (plugin, cb)->
      plugin inst, (err)->
        cb err, inst
    async.each inst.plugins.pre.create, preCreate, (err, results)->
      if err
        stop = err
    if stop
      return null

    res = jsonschema.validate inst.doc, @schema
    if res.errors.length
      inst.invalid = res
      inst.doc = {}
    else
      inst.invalid = false
      @emit 'create', inst

    # run post-create plugins after validation
    # but before returning
    postCreate = (plugin, cb)->
      plugin inst, (err)->
        cb err, inst
    async.each inst.plugins.post.create, postCreate, (err, results)->
      if err
        stop = err
    if stop
      return null
    inst

  get: (key, callback)->
    self = @
    con = @connection
    if not con
      return callback errmsg:'not connected'
    @connection.get bucket:@bucket, key:key, (reply)->
      if reply and reply.content and reply.content[0]
        inst = self.create JSON.parse reply.content[0].value, reply
        inst.links = reply.content[0].links
        inst.reply = reply
        inst.key = key
      else
        inst = null
      callback null, inst

# { content:
#    [ { value: '{"e":5,"f":6}',
#        content_type: 'application/json',
#        vtag: '58VwhV1xnOUOKl8VjT1Uj3',
#        links: [Object],
#        last_mod: 1369679311,
#        last_mod_usecs: 898272 } ],
#   vclock: <Buffer 6b ce ... 2c 00> }
#

  del: (callback)->
    con = @connection
    if not con
      return callback errmsg:'not connected'
    self = @
    if not self.key
      return callback errmsg:'no key'

    preDel = (plugin, cb)->
      plugin self, (err)->
        cb err, self
    cont = true
    async.each self.plugins.pre.del, preDel, (err, results)->
      if err
        cont = false
        callback err, self
    if not cont
      return
    self.emit 'delete', self
    con.del bucket:self.bucket, key:self.key, (reply)->
      self.deleted = true
      if self.plugins.post.del.length
        postDel = (plugin, cb)->
          plugin self, (err)->
            cb err, self
        async.each self.plugins.post.del, postDel, (err, results)->
          callback err, self
      else
        callback null, self

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

    cont = true
    preSave = (plugin, cb)->
      plugin self, (err)->
        cb err, self
    async.each self.plugins.pre.save, preSave, (err, results)->
      if err
        cont = false
        callback err, self
    if not cont
      return
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

    op = if self.key then 'update' else 'insert'
    self.connection.put request, (reply)->
      self.key = reply.key if reply.key
      self.emit op, self

      if self.plugins.post.save.length
        postSave = (plugin, cb)->
          plugin self, (err)->
            cb err, self
        async.each self.plugins.post.save, postSave, (err, results)->
          callback err, self
      else
        callback null, self

  toJSON: ->
    @doc

  plugin: (plugin, options)->
    plugin @, options

  pre: (kwd, callable)->
    if not @plugins.pre[kwd]?
      throw new Error "Model does not support pre #{kwd}"
    @plugins.pre[kwd].push callable

  post: (kwd, callable)->
    if not @plugins.post[kwd]?
      throw new Error "Model does not support post #{kwd}"
    @plugins.post[kwd].push callable

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
