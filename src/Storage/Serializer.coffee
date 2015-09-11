_ = require "underscore"
Util = require "../Util/Util"


module.exports = class Serializer
  constructor: (builtInObjects) ->
    @builtIn = {}
    for object in builtInObjects
      id = Util.getId(object)
      @builtIn[id] = object


  # ===========================================================================
  # Serialization
  # ===========================================================================

  shouldSerializeProperty: (key, value) ->
    # Won't serialize functions.
    return false if _.isFunction(value)
    # Won't serialize a key starting with __
    return false if key.slice(0, 2) == "__"
    return true

  jsonify: (rootValue) ->
    objects = {} # id : json

    jsonifyValue = (value) =>
      if _.isArray(value)
        return jsonifyArray(value)
      else if _.isObject(value)
        return referenceTo(value)
      else
        return value

    jsonifyArray = (array) =>
      return (jsonifyValue(childValue) for childValue in array)

    referenceTo = (object) =>
      id = Util.getId(object)
      if !@builtIn[id] and !objects[id]
        # We'll need to jsonify the object and add it to objects. First, set a
        # placeholder value so recursive references work.
        objects[id] = "PROCESSING"
        objects[id] = jsonifyObject(object)
      return {__ref: id}

    jsonifyObject = (object) =>
      result = {}
      # Annotate key/values.
      for own key, value of object
        if @shouldSerializeProperty(key, value)
          result[key] = jsonifyValue(value)
      # Annotate prototype.
      proto = Object.getPrototypeOf(object)
      unless proto == Object.prototype
        result.__proto = jsonifyValue(proto)
      return result

    root = jsonifyValue(rootValue)
    return {objects, root}


  # ===========================================================================
  # Deserialization
  # ===========================================================================

  dejsonify: ({objects, root}) ->
    # First construct all the objects with appropriate prototype chain.
    constructedObjects = {} # id : object

    constructObject = (id) =>
      return constructedObjects[id] if constructedObjects[id]?
      return @builtIn[id] if @builtIn[id]?
      objectJson = objects[id]
      protoRef = objectJson.__proto
      if protoRef
        proto = constructObject(protoRef.__ref)
        constructedObject = Object.create(proto)
        constructedObject.constructor?()
      else
        constructedObject = {}
      return constructedObjects[id] = constructedObject

    for own id, object of objects
      constructObject(id)

    # Assign key/values.
    assignKeyValues = (id, spec) =>
      constructedObject = constructedObjects[id]
      for own key, value of spec
        continue if key == "__proto"
        constructedObject[key] = deref(value)

    deref = (value) =>
      if _.isArray(value)
        return _.map value, deref
      if _.isObject(value)
        if value.__ref?
          id = value.__ref
          return @builtIn[id] ? constructedObjects[id]
        else
          return _.mapObject value, deref
      else
        return value

    for own id, object of objects
      assignKeyValues(id, object)

    return deref(root)
