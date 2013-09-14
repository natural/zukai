{assign, clone, each, map} = require 'lodash'
{Validator} = require 'jsonschema'
{EventEmitter2} = require 'eventemitter2'
{pluralize} = require 'inflection'
setName = require 'function-name'


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

    if options.indexes?
      inst.indexes = clone options.indexes, true
    else
      inst.indexes = []

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

  @get: ->
    @create {}

  @keys: ->
    [1,2,3]

  @purge: ->
    'purge bucket'

  @indexSearch: ->
    'index search bucket'

  # Model-level delete by specified key:
  @del: (key)->
    'class del, by key'
    [key, @]

  # Instance-level delete by own key:
  del: (arg)->
    'instance del'
    [arg, @]

  put: ->
    'instance put'
    @

  rename: ->
    'instance rename'

  walk: ->
    'instance walk'

  link: ->
    'instance link'

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


exports.createModel = createModel = (defn, base=BaseModel)->
  name = defn?.name
  if not name
    throw new Error 'Model name required'

  if not defn.bucket
    defn.bucket = pluralize name.toLowerCase()

  bucket = defn.bucket
  schema = clone (defn.schema or {}), true


  modelClass = class extends base
    @bucket: bucket
    @connection: defn.connection or null
    @hooks: clone base.hooks
    @schema: schema
    @defaultDelDefn: clone base.defaultDelDefn, true
    @defaultGetDefn: clone base.defaultGetDefn, true
    @defaultPutDefn: clone base.defaultPutDefn, true
    @validator: new Validator
    @server: new EventEmitter2 (defn.events or {})

  setName modelClass, name
  modelClass
