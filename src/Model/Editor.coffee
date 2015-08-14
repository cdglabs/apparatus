_ = require "underscore"
Model = require "./Model"
Util = require "../Util/Util"
Storage = require "../Storage/Storage"


module.exports = class Editor
  constructor: ->
    @project = new Model.Project()
    @_setupSerializer()

  _setupSerializer: ->
    builtInObjects = []
    for own name, object of Model
      if _.isFunction(object)
        object = object.prototype
      Util.assignId(object, name)
      builtInObjects.push(object)
    @serializer = new Storage.Serializer(builtInObjects)


  load: (jsonString) ->
    # TODO: check type and version to ensure it's a valid jsonString.
    json = JSON.parse(jsonString)
    @project = @serializer.dejsonify(json)

  save: ->
    json = @serializer.jsonify(@project)
    json.type = "Apparatus"
    # TODO: get version via build process / ENV variable?
    json.version = "0.4.0"
    jsonString = JSON.stringify(json)
    return jsonString



