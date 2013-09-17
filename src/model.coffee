{assign, clone, defaults, each, map} = require 'lodash'
{Validator, validate} = require 'jsonschema'
{EventEmitter2} = require 'eventemitter2'
{pluralize} = require 'inflection'
setName = require 'function-name'
async = require 'async'
q = require 'q'




# This is the base/meta class for models.  Subclasses are created
# as needed by the createModel function below.
exports.BaseModel = class BaseModel
  @bucket: null
  @contentType: 'application/json'
  @schema: {}

  @hooks:
    pre: {create: [], put: [], del: {}}
    post: {create: [], put: [], del: {}}

  @pre: ->
    'imma pre plugin'

  @post: ->
    'imma post plugin'

  @create: (options)->
    cls = @
    inst = new cls
    inst.key = options.key or null

    # copy some class properties; these can be modified per instance
    for name in ['connection', 'bucket', 'contentType']
      inst[name] = cls[name]

    # shadow other class properties; these can't be modified per instance
    for name in ['schema', 'validator']
      do(name)->
        Object.defineProperty inst, name, get: -> cls[name]

    #if options.indexes?
    #  inst.indexes = clone options.indexes, true
    #else
    #  inst.indexes = []

    if options.doc?
      inst.doc = clone options.doc, true
    else
      inst.doc = {}
    inst.setDefaults inst, inst.schema, inst.doc

    validation = cls.validator.validate inst.doc, cls.schema

    if validation?.errors?.length
      inst.invalid = validation
      inst.doc = {}
    else
      inst.invalid = false
      map cls.hooks.post.create, (hook)-> hook inst
      cls.server.emit 'create', inst

    # pre-create hooks

    # if valid, run post-create hooks, emit 'create'

    inst

  @get: (key, options, callback)->
    if typeof key == 'object'
      options = key
      key = options.key
    if typeof options == 'function'
      callback = options
      options = {}

    cls = @
    deferred = q.defer()

    if not cls.connection
      deferred.reject message: 'Not connected'
      return deferred.promise.nodeify callback

    if typeof options == 'function'
      callback = options
    else if not options
      options = {}

    request = bucket: cls.bucket, key: key
    defaults request, options, cls.defaultGetOptions

    cls.connection.get request, (reply)->
      if reply?.errmsg
        deferred.reject message: reply.errmsg
      else if reply?.content
        objects = map reply.content, (result)->
          if not options.head
            content = cls.decode result.value
          else
            content = {}
          inst = cls.create key: key, doc: content
          assign inst, links: result.links, reply: reply, key: key

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
    if typeof options == 'function'
      callback = options
    else if not options
      options = {}
    @constructor.del key: @key, callback


  @del: (options, callback)->
    cls = @
    deferred = q.defer()

    if not cls.connection
      deferred.reject message: 'Not connected'
      return deferred.promise.nodeify callback

    if typeof options == 'function'
      callback = options
    else if not options
      options = {}


    key = options.key
    if not key
      deferred.reject message: 'No key'
      return deferred.promise.nodeify callback

    run = (hook, cb)->
      hook cls, (err)->
        cb err, cls

    async.each (cls.getHooks 'pre', 'del'), run, (err, results)->
      if err
        deferred.reject message: err
      else
        request = bucket: cls.bucket, key: key #, vclock: cls.vclock
        defaults request, options, cls.defaultDelOptions


        cls.connection.del request, (reply)->
          if reply.errmsg
            deferred.reject message: reply.errmsg
          else
            #cls.deleted = true
            #cls.reply = reply
            async.each (cls.getHooks 'post', 'del'), run, (err)->
              if err
                deferred.reject message: err
              else
                cls.server.emit 'del', key
                deferred.resolve null
    deferred.promise.nodeify callback

  @keys: (callback)->
    @connection.getKeys bucket: @bucket, callback

  @purge: (options, callback)->
    cls = @
    deferred = q.defer()

    if not cls.connection
      deferred.reject message: 'Not connected'
      return deferred.promise.nodeify callback

    if typeof options == 'function'
      callback = options
    else if not options
      options = {}

    cls.keys (reply)->
      run = (key, cb)->
        cls.del key: key, (err)->
          cb err
      async.each (reply.keys or []), run, (err, results)->
        if err
          deferred.reject err
        else
          deferred.resolve results
    deferred.promise.nodeify callback

  @indexSearch: ->
    'index search bucket'


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

    validation = validate self.doc, self.schema

    if validation?.errors?.length
      self.invalid = validation
      deferred.reject message: 'Invalid'
      return deferred.promise.nodeify callback

    run = (hook, cb)->
      hook self, (err)->
        cb err, self

    async.each (self.constructor.getHooks 'pre', 'put'), run, (err, results)->
      if err
        return deferred.reject message: err

      request =
        bucket: self.bucket
        content:
          value: self.encode self.doc
          content_type: self.contentType
          indexes: [] # self.indexes() or []
          links: [] # self.links

      defaults request, options, self.defaultPutOptions
      request.key = self.key if self.key?
      request.vclock = self.reply.vclock if self.reply?.vclock?

      self.connection.put request, (reply)->
        if reply.errmsg
          return deferred.reject message: reply.errmsg

        self.key = reply.key if reply.key
        self.reply = reply

        async.each (self.constructor.getHooks 'post', 'put'), run, (err, results)->
          if err
            self.invalid = err
            deferred.reject message: err
          else
            self.invalid = false
            self.constructor.server.emit 'put', self
            deferred.resolve self

    deferred.promise.nodeify callback


  rename: ->
    'instance rename'

  walk: ->
    'instance walk'

  link: ->
    'instance link'

  encode: (v)->
    JSON.stringify v

  @decode: (v)->
    JSON.parse v


  setDefaults: (object, schema, doc)->
    each schema.properties, (prop, name)->
      if not doc[name]?
        def = prop.default
        if def isnt undefined
          if typeof def == 'function'
            def = def()
          if def isnt undefined
            def = JSON.parse JSON.stringify def
        else
          if prop.type == 'object'
            def = {}
        doc[name] = def

        if prop.properties
          object.setDefaults object, prop, doc[name]

  @getHooks: (type, kwd)->
    hooks = @hooks[type][kwd]
    if not hooks.length
      [(o, n)-> n()]
    else
      hooks

  @defaultGetOptions:
    r: 'default'
    pr: 'default'
    basic_quorum: false
    notfound_ok: false
    if_modified: null
    head: false
    deletedvclock: true

  @defaultDelOptions:
    rw: 'default'
    vclock: null
    r: 'default'
    w: 'default'
    pr: 'default'
    pw: 'default'
    pd: 'default'

  @defaultPutOptions:
    vclock: null
    w: 'default'
    dw: 'default'
    return_body: false
    pw: 'default'
    if_not_modified: false
    if_none_match: false
    return_head: false



exports.registry = registry = {}


exports.Model = (defn, base=BaseModel)->
  name = defn?.name
  if not name
    throw new Error 'Model name required'

  if not defn.bucket
    defn.bucket = pluralize name.toLowerCase()

  bucket = defn.bucket
  schema = clone (defn.schema or {}), true

  modelClass = class Model extends base
    @bucket: bucket
    @connection: defn.connection or null
    @hooks: clone base.hooks
    @schema: schema
    @defaultDelDefn: clone base.defaultDelDefn, true
    @defaultGetDefn: clone base.defaultGetDefn, true
    @defaultPutDefn: clone base.defaultPutDefn, true
    @validator: new Validator
    @server: new EventEmitter2 (defn.events or {})
    @indexes: ->
      []

  modelClass = clone modelClass, true
  setName modelClass, name
  modelClass
