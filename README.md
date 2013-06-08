[![Build Status](https://travis-ci.org/natural/zukai.png)](https://travis-ci.org/natural/zukai)

## zukai
Riak ODM for Node.js.


#### Features

  * Uses the Riak PBC interface via [RiakPBC](https://github.com/nlf/riakpbc)
  * Uses [jsonschema](https://github.com/tdegrunt/jsonschema) for schema definitions and [validation](http://json-schema.org/latest/json-schema-validation.html)
  * Uses [Q](https://github.com/kriskowal/q) for both Promise and conventional Node.js callbacks


#### Contents

  * [Install](#install)
  * [Example](#example)
  * [Plugins](#plugins)
  * [Hooks](#hooks)
  * [Events](#events)
  * [API](#api)
  * [Changelog](#changelog)
  * [About](#about)
  * [License](#license)


<a id="install"></a>
#### Install

Installation is easy.  Add `--save` to the end of the install to update
your project `package.json`.

```sh
$ npm install zukai
```


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

Pre- and post-create hooks are called synchronously and are passed only one
value, the object.  All other hooks are called asynchronously and are passed two
values, the object and the continuation callback.  Asynchronous hooks must call
the continuation callback (i.e., `next()`) to continue processing the operation,
and may indicate an error by supplying a value, e.g., `next(my_error)`.


###### `Model.pre('create', callback)`

Pre-create hooks run after a new object is created and default properties are
set, but before the object document is validated.  Example:

```coffee
Book.pre 'create', (object)->
  object.doc.title = object.doc.title.toUpperCase()
```

###### `Model.post('create', callback)`

Post-create hooks run after the object document is validated but before the
object is returned from the `create` function.

###### `Model.pre('del', callback)`

Pre-delete hooks run before the object is removed from the bucket.  If a hook
indicates an error (by calling `next()` with a value), the object will not be
removed and the promise will be rejected.

###### `Model.post('del', callback)`

Post-delete hooks run after the object is successfully removed from the bucket,
but before the `del` event is emitted and before the promise is resolved.  Any
error produced by a post-delete hook will cause the promise to be rejected.

###### `Model.pre('put', callback)`

Pre-put hooks run before the object is put to the bucket.  If the hook indicates
an error, the object will not be saved.  Example:

```coffee
Book.pre 'put', (object, next)->
  object.doc.title = object.doc.title.toUpperCase()
  next()
```

###### `Model.post('save', callback)`

Post-put hooks run after the object is successfully saved to the bucket, but
before the `put` event is emitted and before the promise is resolved.  Any error
produced by a post-put hook will cause the promise to be rejected.


<a id="events"></a>
#### Events

Models emit events using
[EventEmitter2](https://github.com/hij1nx/EventEmitter2).  The value passed to
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

Static method that creates and returns an object of the given Model.

  * `key`, optional string, if given will be the key for the object
  within the bucket
  * `values`, optional hash, properties to set on the model object


###### `Model.get([key], [options], [callback])`

Static method that reads the value at the given key from the model's bucket.
Returns a promise.

  * `key`, required string if not present in `options`, string, the key to read
  * `options`, optional hash, passed to the connection `get` call
  * `callback`, optional function, called with `(error, object)` after read
  is complete.


###### `object.put([options], [callback])`

Static method to save the object document to the model's bucket.  Returns a
promise.

  * `options`, optional hash, passed to the connection `put` call
  * `callback`, optional function, called with `(error)` after save
  is complete.


###### `object.del([options], [callback])`

Deletes the model object from the model's bucket.  Returns a promise.

  * `options`, optional hash, passed to the connection `del` call
  * `callback`, optional function, called with `(error)` after delete is
    complete.



###### `object.relate(tag, target, [dupes=false])`

Associates the object with the target using the given tag using links.  Pass in
a truthy value as the third argument to allow multiple links for the same
key/bucket/tag triple.

  * `tag` required string, the name to use for the relationship
  * `target` required model object, the object to relate to this one

Note that the object is not put to the bucket after relating it to another
object, you have to do that manually.


###### `object.walk([options], [callback])`

Retrieves the model objects(s) associated with this one.  Returns a promise that
resolves to the related objects, or `null` if no related objects exist.

  * `options`, optional hash, supply a `tag` key with the named relation, or
    `'*'` to retrieve all related objects
  * `callback`, optional function, called with `(err, documents)` when the walk
    is complete

The walk function makes a map reduce request that fetches the related documents
with one request.


###### `object.indexSearch(query, [callback])`

Makes an index search request, using the index and parameters in the `query`
hash.  The callback is run with `(err, keys)` when complete.  Returns a promise.

  * `query`, required hash, supply `qtype` and other query parameters
  * `callback`, optional function, called when complete


###### `object.doc`

The current model object's document.  This is the value read and written to the
model's bucket.

###### `object.invalid`

This attribute will be an error object if the object document failed schema
validation, otherwise it will be `false`.


###### `object.reply`

The last reply from the client connection.  This value is used internally the various
model object functions (for the vector clock, etc).


###### `object.pre(keyword, callable)`

Installs a hook to run before the given keyword.

  * `keyword` required string, one of `create`, `put`, `del`
  * `callable` required function, the hook function to run


###### `object.post(keyword, callable)`

Installs a hook to run after the given keyword.

  * `keyword` required string, one of `create`, `put`, `del`
  * `callable` required function, the hook function to run

###### `object.toJSON()`

Returns an object suitable for serialization.  Unless replaced, this function
returns the `object.doc` value.


###### `object.plugin(factory, options)`

Runs the plugin factory, passing the Model and options objects to it.  See the
[Plugins](#plugins) section above.


###### `object.decode(string)`

Decodes the given string into a document.  The default implementation is
`JSON.parse`.  Replace `encode` and `decode` methods if you need to use
documents that are not JSON.


###### `object.encode(value)`

Encodes the given value into a string.  The default implementation is
`JSON.stringify`.


###### `Model.defaultPutOptions`

Hash with the default values used when calling the connection `put` method.  The
keys and values in the hash mirror the defaults in the [PBC Store Object](http://docs.basho.com/riak/latest/references/apis/protocol-buffers/PBC-Store-Object/)
documentation.


###### `Model.defaultGetOptions`

Hash with the default values used when calling the connection `get` method.  The
keys and values in the hash mirror the defaults in the [PBC Fetch Object](http://docs.basho.com/riak/latest/references/apis/protocol-buffers/PBC-Fetch-Object/)
documentation.


###### `Model.defaultDelOptions`

Hash with the default values used when calling the connection `del` method.  The
keys and values in the hash mirror the defaults in the [PBC Delete Object](http://docs.basho.com/riak/latest/references/apis/protocol-buffers/PBC-Delete-Object/)
documentation.


###### `Model.registry` and `object.registry`

Hash with all models created by the library.  Super nice for looking up models
by name at runtime.  Used internally by the `walk` function to instantiate
related values into model objects.


###### `object.setDefaults(schema, doc)`

Called to update `doc` with default values.

###### `object.getDefault(property)`

Called to get the default value from the schema property.  If the value is a
function, it's called without arguments and its result is used as the default
value.


#### Changelog

###### 05 June 2013 - release 0.1.1
 * minor bugfixes
 * more tests

###### 01 June 2013 - release 0.1.0
  * intial release


#### About

[As far as I can tell](http://translate.google.com/#ja/en/%E5%9B%B3%E8%A7%A3),
"zukai" (図解) is a Japanese word for "schematic".


#### License

Copyright 2013, Troy Melhase.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this work except in compliance with the License. You may obtain a copy of the
License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
