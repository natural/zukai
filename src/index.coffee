async = require 'async'
inflection = require 'inflection'
jsonschema = require 'jsonschema'
under = require 'underscore'
q = require 'q'

{EventEmitter2} = require 'eventemitter2'


exports.plugins = require('./plugins').plugins


exports.createModel = (name, defn)->
  if typeof name == 'object'
    defn = name
    name = defn.name
  else if not defn
    defn = {}

  if not name
    throw new TypeError 'Model name required'

  if not defn.bucket
    defn.bucket = inflection.pluralize name.toLowerCase()

  base =
    hooks:
      pre:  {create:[], put:[], del:[]}
      post: {create:[], put:[], del:[]}
    schema: defn.schema or {}

  server = new EventEmitter2 defn.events
  delete defn.events

  # hm...
  #if defn.connection
  #  defn.connection.client.setNoDelay()
  #  defn.connection.client.setKeepAlive()

  ProtoModel.registry[defn.bucket] = under.extend server,
    exports.ProtoModel, base, defn


exports.ProtoModel = ProtoModel =
  # These properties are totally replaced by createModel;
  # however, puting them here allows for direct use of
  # the model.  That's crazy, tho, so don't do it.
  name: 'ProtoModel'
  bucket: 'undefined'
  connection: null
  contentType: 'application/json'
  hooks:
    pre:  {create:[], put:[], del:[]}
    post: {create:[], put:[], del:[]}
  schema: {}

  # The registry is shared by reference and is not
  # replaced by createModel.
  registry: {}

  indexes: ->

  create: (key, doc)->
    if typeof key == 'object'
      doc = key
      key = doc.key or null
      delete doc.key
    else if not key and not doc
      doc = {}

    self = @
    inst = under.extend {}, self, key: key, doc: doc, links: [], reply: {}
    inst.setDefaults inst.schema, inst.doc
    under.map inst.hooks.pre.create, (hook)-> hook inst
    validation = jsonschema.validate inst.doc, self.schema

    if validation?.errors?.length
      inst.invalid = validation
      inst.doc = {}
    else
      inst.invalid = false
      under.map inst.hooks.post.create, (hook)-> hook inst
      self.emit 'create', inst
    inst


  get: (key, options, callback)->
    if typeof key == 'object'
      options = key
      key = options.key
    if typeof options == 'function'
      callback = options
      options = {}

    self = @
    deferred = q.defer()

    if not self.connection
      deferred.reject message: 'Not connected'
      return deferred.promise.nodeify callback

    if typeof options == 'function'
      callback = options
    else if not options
      options = {}

    request = bucket: self.bucket, key: key
    under.defaults request, options, self.defaultGetOptions

    self.connection.get request, (reply)->
      if reply?.errmsg
        deferred.reject message: reply.errmsg
      else if reply?.content
        objects = under.map reply.content, (result)->
          if not options.head
            content = self.decode result.value
          else
            content = {}
          inst = self.create key, content
          under.extend inst, links: result.links, reply: reply, key: key

        objects = objects[0] if objects.length == 1
        if options.walk and objects.links?
          objects.walk(options.walk).then (docs)->
            deferred.resolve [objects].concat docs
        else
          deferred.resolve objects
      else
        deferred.resolve null
    deferred.promise.nodeify callback


  del: (options, callback)->
    self = @
    deferred = q.defer()

    if not self.connection
      deferred.reject message: 'Not connected'
      return deferred.promise.nodeify callback

    if not self.key
      deferred.reject message: 'No key'
      return deferred.promise.nodeify callback

    if typeof options == 'function'
      callback = options
    else if not options
      options = {}

    run = (hook, cb)->
      hook self, (err)->
        cb err, self

    async.each (self.getHooks 'pre', 'del'), run, (err, results)->
      if err
        deferred.reject message: err
      else
        request = bucket: self.bucket, key: self.key, vclock: self.vclock
        under.defaults request, options, self.defaultDelOptions

        self.connection.del request, (reply)->
          if reply.errmsg
            deferred.reject message: reply.errmsg
          else
            self.deleted = true
            self.reply = reply
            async.each (self.getHooks 'post', 'del'), run, (err)->
              if err
                deferred.reject message: err
              else
                self.emit 'del', self
                deferred.resolve null
    deferred.promise.nodeify callback


  put: (options, callback)->
    self = @
    deferred = q.defer()

    if not self.connection
      deferred.reject message: 'Not connected'
      return deferred.promise.nodeify callback

    if typeof options == 'function'
      callback = options
    else if not options
      options = {}

    validation = jsonschema.validate self.doc, self.schema

    if validation?.errors?.length
      self.invalid = validation
      deferred.reject message: 'Invalid'
      return deferred.promise.nodeify callback

    run = (hook, cb)->
      hook self, (err)->
        cb err, self

    async.each (self.getHooks 'pre', 'put'), run, (err, results)->
      if err
        return deferred.reject message: err

      request =
        bucket: self.bucket
        content:
          value: self.encode self.doc
          content_type: self.contentType
          indexes: self.indexes() or []
          links: self.links

      under.defaults request, options, self.defaultPutOptions
      request.key = self.key if self.key?
      request.vclock = self.reply.vclock if self.reply?.vclock?

      self.connection.put request, (reply)->
        if reply.errmsg
          return deferred.reject message: reply.errmsg

        self.key = reply.key if reply.key
        self.reply = reply

        async.each (self.getHooks 'post', 'put'), run, (err, results)->
          if err
            self.invalid = err
            deferred.reject message: err
          else
            self.invalid = false
            self.emit 'put', self
            deferred.resolve self

    deferred.promise.nodeify callback


  walk: (options, callback)->
    tag = bucket = '*'
    switch typeof options
      when 'string'
        tag = options
      when 'object'
        tag = options.tag if options.tag
        bucket = options.bucket if options.bucket
      when 'function'
        callback = tag

    self = @
    deferred = q.defer()
    get = (v)-> [bucket:v.bucket, data:(Riak.mapValuesJson v), key:v.key]

    if tag == '*'
      links = self.links
    else
      links = under.filter self.links, (lnk)->lnk.tag == tag

    if bucket and bucket != '*'
      links = under.filter links, (lnk)->lnk.bucket == bucket

    if not links.length
      deferred.resolve []
      return deferred.promise.nodeify callback

    request =
      inputs: ([lnk.bucket, lnk.key] for lnk in links)
      query: [
        {map: {language: 'javascript', source: get.toString()}}
        ]
    query =
      request: JSON.stringify request
      content_type: self.contentType

    self.connection.mapred query, (docs)->
      docs = docs or {}

      objects = under.map docs[0], (doc)->
        model = self.registry[doc.bucket]
        if model
          return model.create doc.key, doc.data

      if under.every objects, ((v)-> not not v)
        deferred.resolve objects
      else
        deferred.reject message: 'Unable to resolve one or more models'

    return deferred.promise.nodeify callback


  relate: (tag, obj, dupes=false)->
    match = (lnk)->
      lnk.tag == tag and lnk.key == obj.key and lnk.bucket == obj.bucket
    if dupes or not under.some @links, match
      @links.push tag: tag, key: obj.key, bucket: obj.bucket


  toJSON: ->
    @doc


  decode: (v)->
    JSON.parse v


  encode: (v)->
    JSON.stringify v


  plugin: (plugin, options)->
    plugin @, options
    @


  pre: (kwd, callable)->
    if not @hooks.pre[kwd]
      throw new Error "Model does not support pre #{kwd}"
    @hooks.pre[kwd].push callable


  post: (kwd, callable)->
    if not @hooks.post[kwd]
      throw new Error "Model does not support post #{kwd}"
    @hooks.post[kwd].push callable


  defaultPutOptions:
    vclock: null
    w: 'default'
    dw: 'default'
    return_body: false
    pw: 'default'
    if_not_modified: false
    if_none_match: false
    return_head: false


  defaultGetOptions:
    r: 'default'
    pr: 'default'
    basic_quorum: false
    notfound_ok: false
    if_modified: null
    head: false
    deletedvclock: true


  defaultDelOptions:
    rw: 'default'
    vclock: null
    r: 'default'
    w: 'default'
    pr: 'default'
    pw: 'default'
    pd: 'default'


  getHooks: (type, kwd)->
    hooks = @hooks[type][kwd]
    if not hooks.length
      [(o, n)-> n()]
    else
      hooks


  setDefaults: (schema, doc)->
    under.each schema.properties, (prop, name)->
      if not doc[name]?
        val = prop.default
        if typeof val == 'function'
          val = val()
        if val isnt undefined
          doc[name] = val
        if prop.properties
          @setDefaults prop, doc[name]


  indexSearch: (query, callback)->
    self = @
    deferred = q.defer()

    under.defaults query,
      bucket: self.bucket
      qtype: 0

    self.connection.getIndex query, (reply)->
      if reply?.keys?
        deferred.resolve reply.keys
      else
        deferred.reject null

    return deferred.promise.nodeify callback


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
