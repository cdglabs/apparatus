_ = require "underscore"
Dataflow = require "../Dataflow/Dataflow"
Model = require "./Model"
Util = require "../Util/Util"
Storage = require "../Storage/Storage"


module.exports = SerializerWithBuiltIns = {}


SerializerWithBuiltIns.getSerializer = ->
  builtInObjects = []
  for own name, object of _builtIn()
    if _.isFunction(object)
      object = object.prototype
    Util.assignId(object, name)
    builtInObjects.push(object)
  return new Storage.Serializer(builtInObjects)

# builtIn returns all of the built in classes and objects that are used as
# the "anchors" for serialization and deserialization. That is, all of the
# objects and classes which should not themselves be serialized but instead
# be *referenced* from a serialization. When deserialized, these references
# are then bound appropriately.
_builtIn = ->
  builtIn = _.clone(Model)
  builtIn["SpreadEnv"] = Dataflow.SpreadEnv
  builtIn["Matrix"] = Util.Matrix
  return builtIn
