_ = require "underscore"
Util = require "../Util/Util"


module.exports = Serializer = new class
  constructor: ->
    @builtIn = {} # id : Object

  loadBuiltInObjects: (builtInObjects) ->
    for object in builtInObjects
      id = Util.getId(object)
      @builtIn[id] = object




  shouldSerializeProperty: (key, value) ->
    # Can't serialize functions. Skip them.
    return false if _.isFunction(value)
    # A key starting with __ should not be serialized.
    return false if key.slice(0, 2) == "__"
    return true

  jsonify: (rootValue) ->
    objects = {} # id : json

    jsonifyValue = (value, force=false) =>
      if _.isArray(value)
        return jsonifyArray(value)
      else if _.isObject(value)
        if force
          return jsonifyObject(value)
        else
          return referenceTo(value)
      else
        return value

    jsonifyArray = (array) =>
      return _.map array, (childValue) => jsonifyValue(childValue)

    referenceTo = (object) =>
      id = Util.getId(object)
      if !@builtIn[id] and !objects[id]
        # We'll need to jsonify the object and add it to objects. First, set a
        # placeholder value so recursive references work.
        objects[id] = "PROCESSING"
        objects[id] = jsonifyValue(object, true)
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



