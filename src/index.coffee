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

    inst = extend {}, self, {key:key, doc:doc, links:[]}
    self.setDefaults self.schema, inst.doc

    for plugin in inst.plugins.pre.create
      plugin inst

    res = jsonschema.validate inst.doc, self.schema
    if res.errors and res.errors.length
      inst.invalid = res
      inst.doc = {}
    else
      inst.invalid = false
      self.emit 'create', inst
      # run post-create plugins after validation
      # but before returning
      for plugin in inst.plugins.post.create
        plugin inst

    inst

  get: (key, callback)->
    self = @
    if not self.connection
      return callback message: 'Not Connected'

    # { content:
    #    [ { value: '{"e":5,"f":6}',
    #        content_type: 'application/json',
    #        vtag: '58VwhV1xnOUOKl8VjT1Uj3',
    #        links: [Object],
    #        last_mod: 1369679311,
    #        last_mod_usecs: 898272 } ],
    #   vclock: <Buffer 6b ce ... 2c 00> }

    self.connection.get bucket:self.bucket, key:key, (reply)->
      if reply and reply.content and reply.content[0]
        inst = self.create JSON.parse reply.content[0].value, reply
        inst.links = reply.content[0].links
        inst.reply = reply
        inst.key = key
      else
        inst = null
      callback null, inst

  del: (callback)->
    self = @
    if not self.connection
      return callback message: 'Not Connected'

    if not self.key
      return callback message: 'No Key'

    plugins = self.getPlugins 'pre', 'del'
    run = (plugin, cb)->
      plugin self, (err)->
        cb err, self
    async.each plugins, run, (err, results)->
      if err
        callback message: err
      else
        self.connection.del bucket: self.bucket, key: self.key, (reply)->
          if reply.errmsg
            callback message: reply.errmsg
          else
            self.deleted = true
            self.emit 'delete', self
            plugins = self.getPlugins 'post', 'del'
            run = (plugin, cb)->
              plugin self, (err)->
                cb err, self
            async.each plugins, run, (err, results)->
              callback err, self

  save: (options, callback)->
    self = @
    if not self.connection
      return callback message: 'Not Connected'

    if typeof options == 'function'
      callback = options

    res = jsonschema.validate self.doc, self.schema

    if res.errors and res.errors.length
      self.invalid = res
      return callback message: 'Invalid'
    else
      self.invalid = false

    plugins = self.getPlugins 'pre', 'save'
    run = (plugin, cb)->
      plugin self, (err)->
        cb err, self

    async.each plugins, run, (err, results)->
      if err
        callback message: err
      else
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
          if reply.errmsg
            callback message: errmsg
          else
            self.key = reply.key if reply.key
            self.emit op, self
            plugins = self.getPlugins 'post', 'save'
            run = (plugin, cb)->
              plugin self, (err)->
                cb err, self
            async.each plugins, run, (err, results)->
              if err
                err = message: err
              callback err, self

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

  getPlugins: (type, kwd)->
    plugins = @plugins[type][kwd]
    if not plugins.length
      plugins = [(o, n)-> n()]
    plugins

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



        # { content:
        #    [ { value: '{"e":5,"f":6}',
        #        content_type: 'application/json',
        #        vtag: '58VwhV1xnOUOKl8VjT1Uj3',
        #        links: [Object],
        #        last_mod: 1369679311,
        #        last_mod_usecs: 898272 } ],
        #   vclock: <Buffer 6b ce ... 2c 00> }
