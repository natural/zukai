{assign, clone} = require 'lodash'
{Validator} = require 'jsonschema'
{EventEmitter2} = require 'eventemitter2'
setName = require 'function-name'



# This is the base/meta class for models.  Subclasses are created
# as needed by the createModel function below.
exports.BaseModel = class BaseModel
  @bucket: null
  @contentType: 'application/json'

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
    for name in ['connection', 'bucket', 'contentType', 'modelName']
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

    # pre-create hooks
    # validation
    # if valid, run post-create hooks, emit 'create'

    inst

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
  bucket = defn.bucket
  schema = clone (defn.schema or {}), true

  server = new EventEmitter2 (defn.events or {})

  modelClass = class extends base
    @modelName: defn.modelName
    @bucket: bucket
    @connection: defn.connection or null
    @hooks: clone base.hooks
    @schema: schema
    @defaultDelDefn: clone base.defaultDelDefn, true
    @defaultGetDefn: clone base.defaultGetDefn, true
    @defaultPutDefn: clone base.defaultPutDefn, true
    validator: new Validator

  assign modelClass, server

  setName modelClass, defn.modelName

  modelClass


Empty = createModel modelName:'Empty', bucket:'e0s'

console.log 'class modelName is correct:', Empty.modelName == 'Empty'
console.log 'class bucket is correct:', Empty.bucket == 'e0s'
console.log 'class has static get:', Empty.get?
console.log ''

e0 = Empty.create {}
console.log 'instance bucket correct:', e0.bucket == 'e0s'
console.log 'instance does not have static get:', not e0.get?
console.log ''

console.log 'class does not have static put:', not Empty.put?
console.log 'instance has non-static put:', (Empty.create {}).put?
console.log ''

e1 = Empty.get 1
console.log 'class get creates instance:', e1.constructor == Empty
console.log 'instance has same bucket as class:', e1.bucket == Empty.bucket
Empty.bucket = 'x'
console.log '... but not after change to class:', e1.bucket == 'e0s'

e1.bucket = 'y'
console.log '... even after change to instance:', e1.bucket == 'y', Empty.bucket == 'x'
console.log ''


e2 = Empty.create {}
console.log 'instance put bound correctly:', e2.put() == e2

con = [44]

Xion = createModel modelName: 'Xion', bucket:'cs', connection: con
console.log 'class gets connection via createModel:', Xion.connection is con
x = Xion.create {}
console.log 'instance gets connection via create:', x.connection is con
console.log ''


D = createModel modelName: 'Deletes', bucket: 'ds'
console.log 'class has static del method:', D.del?
[k, cls] = D.del('key')
console.log 'class static del method returns cls:', k=='key', cls==D

d = D.create {}
console.log 'instance has del method:', d.del?
[i, obj] = d.del('key')
console.log 'instance del method returns instance:', i=='key', d==obj
