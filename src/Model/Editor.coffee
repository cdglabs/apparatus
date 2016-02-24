_ = require "underscore"
queryString = require "query-string"
Dataflow = require "../Dataflow/Dataflow"
Model = require "./Model"
Util = require "../Util/Util"
Storage = require "../Storage/Storage"
FirebaseAccess = require "../Storage/FirebaseAccess"


module.exports = class Editor
  constructor: ->
    @_setupLayout()
    @_setupSerializer()
    @_setupProject()
    @_setupRevision()
    @_parseQueryString()

  _setupLayout: ->
    @layout = new Model.Layout()

  _setupProject: ->
    @loadFromLocalStorage()
    if !@project
      @createNewProject()

  _setupSerializer: ->
    builtInObjects = []
    for own name, object of @_builtIn()
      if _.isFunction(object)
        object = object.prototype
      Util.assignId(object, name)
      builtInObjects.push(object)
    @serializer = new Storage.Serializer(builtInObjects)

  # Checks if we should load an external JSON file based on the query string
  # (the ?stuff at the end of the URL).
  _parseQueryString: ->
    parsed = queryString.parse(location.search)
    if parsed.experimental == '1'
      @experimental = true
    if parsed.load
      @loadFromURL(parsed.load)
    else if parsed.loadFirebase
      @loadFromFirebase(parsed.loadFirebase)

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
  version: "0.4.1"

  loadJsonStringIntoProject: (jsonString) ->
    json = JSON.parse(jsonString)
    # TODO: If the file format changes, this will need to check the version
    # and convert or fail appropriately.
    if json.type == "Apparatus"
      @project = @serializer.dejsonify(json)

  loadJsonStringIntoProjectFromExternalSource: (jsonString) ->
    @loadJsonStringIntoProject(jsonString)
    @checkpoint()
    Apparatus.refresh()  # HACK: calling Apparatus seems funky here.

  mergeJsonStringIntoProject: (jsonString) ->
    json = JSON.parse(jsonString)
    # TODO: If the file format changes, this will need to check the version
    # and convert or fail appropriately.
    if json.type == "Apparatus"
      otherProject = @serializer.dejsonify(json)
      for createPanelElement in otherProject.createPanelElements
        if createPanelElement not in @project.createPanelElements
          @project.createPanelElements.push(createPanelElement)

  mergeJsonStringIntoProjectFromExternalSource: (jsonString) ->
    @mergeJsonStringIntoProject(jsonString)
    @checkpoint()
    Apparatus.refresh()  # HACK: calling Apparatus seems funky here.

  getJsonStringOfProject: ->
    json = @serializer.jsonify(@project)
    json.type = "Apparatus"
    json.version = @version
    jsonString = JSON.stringify(json)
    return jsonString

  createNewProject: ->
    @project = new Model.Project()


  # ===========================================================================
  # Local Storage
  # ===========================================================================

  localStorageName: "apparatus"

  saveToLocalStorage: ->
    jsonString = @getJsonStringOfProject()
    window.localStorage[@localStorageName] = jsonString
    return jsonString

  loadFromLocalStorage: ->
    jsonString = window.localStorage[@localStorageName]
    if jsonString
      @loadJsonStringIntoProject(jsonString)

  resetLocalStorage: ->
    delete window.localStorage[@localStorageName]


  # ===========================================================================
  # File System
  # ===========================================================================

  saveToFile: ->
    jsonString = @getJsonStringOfProject()
    fileName = @project.editingElement.label + ".json"
    Storage.saveFile(jsonString, fileName, "application/json;charset=utf-8")

  loadFromFile: ->
    Storage.loadFile (jsonString) =>
      @loadJsonStringIntoProjectFromExternalSource(jsonString)

  mergeFromFile: ->
    Storage.loadFile (jsonString) =>
      @mergeJsonStringIntoProjectFromExternalSource(jsonString)


  # ===========================================================================
  # External URL
  # ===========================================================================

  # TODO: Deal with error conditions, timeout, etc.
  # TODO: Maybe move xhr stuff to Util.
  # TODO: Show some sort of loading indicator.
  loadFromURL: (url) ->
    xhr = new XMLHttpRequest()
    xhr.onreadystatechange = =>
      return unless xhr.readyState == 4
      return unless xhr.status == 200
      jsonString = xhr.responseText
      @loadJsonStringIntoProjectFromExternalSource(jsonString)
    xhr.open("GET", url, true)
    xhr.send()

  loadFromFirebase: (key) ->
    @firebaseAccess ?= new FirebaseAccess()

    @firebaseAccess.loadDrawingPromise(key)
      .then (drawingData) =>
        jsonString = drawingData.source
        @loadJsonStringIntoProjectFromExternalSource(jsonString)
      .catch (error) =>
        if error instanceof FirebaseAccess.DrawingNotFoundError
          console.warn "Drawing #{key} not found in Firebase!"
        else
          throw error
      .done()

  saveToFirebase: ->
    @firebaseAccess ?= new FirebaseAccess()

    jsonString = @getJsonStringOfProject()
    @firebaseAccess.saveDrawingPromise(jsonString)
      .then (key) ->
        window.prompt(
          'Saved successfully! Copy this link:',
          # TODO: Remove experimental=1 when Firebase access is taken out of
          # experimental mode
          'http://aprt.us/editor/?experimental=1&loadFirebase=' + key)
      .done()


  # ===========================================================================
  # Revision History
  # ===========================================================================

  _setupRevision: ->
    # @current is a JSON string representing the current state. @undoStack and
    # @redoStack are arrays of such JSON strings.
    @current = @getJsonStringOfProject()
    @undoStack = []
    @redoStack = []
    @maxUndoStackSize = 100

  checkpoint: ->
    jsonString = @saveToLocalStorage()
    return if @current == jsonString
    @undoStack.push(@current)
    if @undoStack.length > @maxUndoStackSize
      @undoStack.shift()
    @redoStack = []
    @current = jsonString

  undo: ->
    return unless @isUndoable()
    @redoStack.push(@current)
    @current = @undoStack.pop()
    @loadJsonStringIntoProject(@current)
    @saveToLocalStorage()

  redo: ->
    return unless @isRedoable()
    @undoStack.push(@current)
    @current = @redoStack.pop()
    @loadJsonStringIntoProject(@current)
    @saveToLocalStorage()

  isUndoable: ->
    return @undoStack.length > 0

  isRedoable: ->
    return @redoStack.length > 0
