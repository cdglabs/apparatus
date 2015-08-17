_ = require "underscore"
Dataflow = require "../Dataflow/Dataflow"
Model = require "./Model"
Util = require "../Util/Util"
Storage = require "../Storage/Storage"


module.exports = class Editor
  constructor: ->
    @_setupSerializer()
    @_setupProject()

  _setupProject: ->
    @loadFromLocalStorage()
    if !@project
      @project = new Model.Project()

  _setupSerializer: ->
    builtInObjects = []
    for own name, object of @_builtIn()
      if _.isFunction(object)
        object = object.prototype
      Util.assignId(object, name)
      builtInObjects.push(object)
    @serializer = new Storage.Serializer(builtInObjects)

  # builtIn returns all of the built in classes and objects that are used as
  # the "anchors" for serialization and deserialization. That is, all of the
  # objects and classes which should not themselves be serialized but instead
  # be *referenced* from a serialization. When deserialized, these references
  # are then bound appropriately.
  _builtIn: ->
    builtIn = _.clone(Model)
    builtIn["SpreadEnv"] = Dataflow.SpreadEnv
    builtIn["Matrix"] = Util.Matrix
    return builtIn

  # TODO: get version via build process / ENV variable?
  version: "0.4.0"

  load: (jsonString) ->
    json = JSON.parse(jsonString)
    if json.type == "Apparatus" and json.version == @version
      @project = @serializer.dejsonify(json)

  save: ->
    json = @serializer.jsonify(@project)
    json.type = "Apparatus"
    json.version = @version
    jsonString = JSON.stringify(json)
    return jsonString


  # ===========================================================================
  # Local Storage
  # ===========================================================================

  localStorageName: "apparatus"

  saveToLocalStorage: ->
    jsonString = @save()
    window.localStorage[@localStorageName] = jsonString

  loadFromLocalStorage: ->
    jsonString = window.localStorage[@localStorageName]
    if jsonString
      @load(jsonString)

  resetLocalStorage: ->
    delete window.localStorage[@localStorageName]


  # ===========================================================================
  # Revision History
  # ===========================================================================

  checkpoint: ->
    @saveToLocalStorage()

  # TODO: undo, redo

