[![Build Status](https://travis-ci.org/natural/zukai.png)](https://travis-ci.org/natural/zukai)

## zukai
Riak ODM for Node.js.


#### Features

  * Uses PBC interface to Riak via [RiakPBC](https://github.com/nlf/riakpbc)
  * Uses [jsonschema](https://github.com/tdegrunt/jsonschema) for schema definitions and [validation](http://json-schema.org/latest/json-schema-validation.html)
  * Uses [Q](https://github.com/kriskowal/q) for both Promise and conventional Node.js APIs


#### Contents

  * [Example](#example)
  * [Plugins](#plugins)
  * [Hooks](#hooks)
  * [Events](#events)
  * [About](#about)
  * [Copyright and License](#copyright)


<a id="example"></a>
#### Example

```coffee
{createClient} = require 'riakpbc'
{createModel} = require 'zukai'

Book = createModel
  name: 'Book'
  bucket: 'books'
  connection: createClient()
  schema:
    properties:
      title:
        type: 'string'
        required: true

bell = Book.create title: 'For Whom the Bell Tolls'
bell.put (err)->
  console.log 'saved'
```


<a id="plugins"></a>
#### Plugins

Plugins are reusable components for Models.  Plugins
typically modify the Model schema, install [hooks](#hooks), or both.  This
example adds a new property named `author`:

```coffee
authorPlugin = (model, options)->
  model.schema.properties.author =
    type: 'string'
    required: true

Books.plugin authorPlugin
```


<a id="hooks"></a>
#### Hooks

Hooks are functions that are called at various points in the life cycle of
objects.

Pre- and post-create hooks are called synchronously and are passed only one value,
the object.  All other hooks are called asynchronously and are passed two values, the
object and the continuation callback.  Asynchronous
hooks must call `next()` to continue processing the operation, and may indicate
an error by supplying a value, e.g., `next(my_error)`.


###### Pre-create

`model.pre('create', callback)`

Pre-create hooks run after a new object is created and default properties are
set, but before the object document is validated.  Example:

```coffee
Book.pre 'create', (object)->
  object.doc.title = object.doc.title.toUpperCase()
```

###### Post-create

`model.post('create', callback)`

Post-create hooks run after the object document is validated but before the
object is returned from the `create` function.

###### Pre-delete

`model.pre('del', callback)`

Pre-delete hooks run before the object is removed from the bucket.  If a hook
indicates an error (by calling `next()` with a value), the object will not be
removed and the promise will be rejected.

###### Post-delete

`model.post('del', callback)`

Post-delete hooks run after the object is successfully removed from the bucket,
but before the `del` event is emitted and before the promise is resolved.  Any
error produced by a post-delete hook will cause the promise to be rejected.

###### Pre-put

`model.pre('put', callback)`

Pre-put hooks run before the object is put to the bucket.  If the hook indicates
an error, the object will not be saved.  Example:

```coffee
Book.pre 'put', (object, next)->
  object.doc.title = object.doc.title.toUpperCase()
  next()
```

###### Post-put

`model.post('save', callback)`

Post-put hooks run after the object is successfully saved to the bucket, but
before the `put` event is emitted and before the promise is resolved.  Any error
produced by a post-put hook will cause the promise to be rejected.


<a id="events"></a>
#### Events

Models emit events (using
[EventEmitter2](https://github.com/hij1nx/EventEmitter2)).  The value passed to
each event is the model object.

Options for the event emitter are passed in via `options.events` to the
`createModel` function.  For example, to enable wildcard events, you would
define your model like this:

```coffee
Talker = createModel
  name: 'Talker'
  events:
    wildcard: true

```

###### `create`

The `create` event is emitted after the object has been fully instantiated and
validated, and after all of the post-create hooks have run.

###### `del`

The `del` event is emitted after the object is removed from the bucket and
after all post-delete hooks have run.

###### `put`

The `put` event is emitted after the object is put to the bucket and after all
post-save hooks have run.


<a id="API"></a>
#### API

###### `zukai.createModel([name], definition)`

Factory function that creates a new Model.

  * `name` optional string, the name of the model.

The `definition` object should have keys thusly:

  * `name`, required string (if first parameter is missing), the name of the model
  * `bucket`, optional, the name of the Riak bucket from which to read and write
  objects
  * `connection`, optional for create (but required for most operations), an instance
  of the RiakPBC client
  * `schema`, optional, JSON schema
  * `methods`, optional, an object of functions to add to the Model
  * `indexes`, optional, a function that returns an array of indexes included in
  the `put()` call.


###### `zukai.ProtoModel`

Prototypical model used to create other models via the `createModel` function
described above.  You can change any property or function on this object to
effect all models created (but you shouldn't really have to, either).

###### `Model.create([key], [values])`

Static method that creates an object of the given Model.  Returns a new model
object.

  * `key`, optional string, if given will be the key for the object
  within the bucket
  * `values`, optional object, properties to set on the model object

###### `Model.get([key], [options], [callback])`

Static method to read the value at the given key from the model's bucket.

  * `key`, required string if not present in `options`, string, the key to read
  * `options`, optional hash, passed to the connection `get` call
  * `callback`, optional function, called with `(error, object)` after read
  is complete.
  * returns a promise

###### `object.put([callback])`

Save the model object.

  * `callback`, required function, called with `(error)` after save
  is complete.
  * returns a promise

###### `object.del([options], [callback])`

Delete the model object.

  * `options`, optional hash, passed to the connection `del` call
  * `callback`, optional function, called with `(error)` after delete is
    complete.
  * returns a promise

###### `object.doc`

The value of the key.

###### `object.invalid`

This attribute will be an error object if the object document failed schema
validation, otherwise it will be `false`.


###### `object.reply`

The last reply from the client connection.  This value is used internally the various
model object functions (for the vector clock, etc).

###### `object.toJSON()`

Returns an object suitable for serialization.  Unless replaced, this function
returns the `object.doc` value.

###### `object.plugin(factory, options)`

Runs the plugin factory, passing the Model and options objects to it.  See the
Plugins section above.

###### `object.relate(tag, target, [dupes=false])`

Associates the object with the target using the given tag using links.  Pass in
a truthy value as the third argument to allow multiple links for the same
key/bucket/tag triple.

###### `object.walk(options, [callback])`

Retrieves the model objects(s) associated with this one.

###### `Model.registry` and `object.registry`

Hash with all models created by the library.  Super nice for looking up models
by name at runtime.  Used internally by the `resolve` function to instantiate
related values into model objects.


###### `object.setDefaults(schema, doc)`

Called to update `doc` with default values.

###### `object.getDefault(property)`

Called to get the default value from the schema property.  If the value is a
function, it's called without arguments and it's result is used as the default
value.


<a id="about"></a>
#### About

[As far as I can tell](http://translate.google.com/#ja/en/%E5%9B%B3%E8%A7%A3),
"zukai" (図解) is a Japanese word for "schematic".


<a id="copyright"></a>
#### Copyright and License

Copyright 2013, Troy Melhase.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this work except in compliance with the License. You may obtain a copy of the
License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
