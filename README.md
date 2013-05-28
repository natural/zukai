zukai
=====

[![Build Status](https://travis-ci.org/natural/zukai.png)](https://travis-ci.org/natural/zukai)

Riak ODM for Node.js.

Uses [RiakPBC](https://github.com/nlf/riakpbc) for speed and [jsonschema](https://github.com/tdegrunt/jsonschema) for familiarity.

Example
-------

```
  {createModel} = require 'zukai'

  Book = createModel
    name: 'Book'
    bucket: 'books'
    schema:
      properties:
        title:
          type: 'string'
          required: true

  bell = Book.create title:'For Whom the Bell Tolls'
```

Plugins
-------

Models have the concept of plugins, functions called at various points in the
life cycle of model objects.

Events
------

Model objects emit the following events:

  * `delete`
  * `update`
  * `insert`
  * `create`

In each case, the object is the only parameter to the event.


API
---

`zukai.createModel(config)`

Factory function that creates a model.  The config object should have keys
thusly:

  * `name`, required, the name of the model
  * `bucket`, optional, the name of the Riak bucket from which to read and write
  objects
  * `connection`, optional for create, required for most operations, an instance
  of the RiakPBC client
  * `schema`, optional, JSON schema
  * `methods`, optional, an object of functions to add to the Model
  * `indexes`, optional, an Array of indexes for the Model


`zukai.ProtoModel`

Prototypical model used to create other models via the `createModel` function
described above.  You can change any property or function on this object to
effect all models created (but you shouldn't really have to, either).

`Model.create([key], [values])`

Factory function that creates an object of the given Model.  Returns a new model
object.

  * `key`, optional string, if given will be the key for the object
  within the bucket
  * `values`, optional object, properties to set on the model object

`Model.get(key, callback)`

Read the value at the given key from the model's bucket.

  * `key`, required string, the key to read
  * `callback`, required function, called with `(error, object)` after read
  is complete.

`object.save(callback)`

Save the model object.

  * `callback`, required function, called with `(error)` after save
  is complete.

`object.del(callback)`

Delete the model object.

  * `callback`, required function, called with `(error)` after delete is
    complete.

`object.doc`

The value of the key.

`object.invalid`

This attribute will be `true` if the object document has been validated against
the Model schema.

`object.reply`

The last reply from the client connection.  This value is used internally the various
model object functions (for the vector clock, etc).

`object.toJSON()`

Returns an object suitable for serialization.  Unless replaced, this function
returns the `object.doc` value.

`object.plugin(factory, options)`

Runs the plugin factory, passing the Model and options objects to it.  See the
Plugins section below.

`object.relate(tag, target, [dupes=false])`

Associates the object with the target using the given tag.  Pass in a truthy
value.

`object.resolve(tag, callback)`

Retrieves the model objects(s) associated with this one by the named tag.  The
callback is called with `(err, objects)` where `objects` is an array of found
model objects.

Internals
---------

I don't believe in hiding code behind private qualifiers, explicit or implicit,
enforced or not.  So you get the following, and note that these may change or
disappear:

`Model.registry` and `object.registry`

Hash with all models created by the library.  Super nice for looking up models
by name at runtime.  Used internally by the `resolve` function to instantiate
related values into model objects.


`object.setDefaults(schema, doc)`

Called to update `doc` with default values.

`object.getDefault(property)`

Called to get the default value from the schema property.  If the value is a
function, it's called without arguments and it's result is used as the default
value.



About the Name
--------------
[As far as I can tell](http://translate.google.com/#ja/en/%E5%9B%B3%E8%A7%A3),
"zukai" (図解) is a Japanese word for "schematic".
