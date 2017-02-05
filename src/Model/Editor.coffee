_ = require "underscore"
queryString = require "query-string"
require "whatwg-fetch"
Model = require "./Model"
Util = require "../Util/Util"
Storage = require "../Storage/Storage"
FirebaseAccess = require "../Storage/FirebaseAccess"

module.exports = class Editor
  constructor: ->
    @layout = new Model.Layout()
    @serializer = Model.SerializerWithBuiltIns.getSerializer()

    parsedQuery = queryString.parse(location.search)

    isSelected = (str) => str and str.trim() == '1'

    if isSelected(parsedQuery.experimental)
      @experimental = true
    if isSelected(parsedQuery.fullScreen)
      @layout.setFullScreen(true)

    if parsedQuery.load
      jsonPromise = @getJsonFromURLPromise(parsedQuery.load)
    else if parsedQuery.loadFirebase
      jsonPromise = @getJsonFromFirebasePromise(parsedQuery.loadFirebase)

    if jsonPromise
      # Remote initial load
      jsonPromise
        .then (json) =>
          @loadJsonStringIntoProject(json)
          @setupRevision()
          Apparatus.refresh()
        .catch (e) =>
          @initialLoadError = e
          Apparatus.refresh()
    else
      @performLocalInitialLoad()

  performLocalInitialLoad: ->
    @loadFromLocalStorage()
    if !@project
      @createNewProject()
    @setupRevision()

  # TODO: get version via build process / ENV variable?
  version: "0.4.1"

  # Given a JSON string, parses it and loads it as the editor's project. This
  # does not modify the revision history, so it is safe for use by undo/redo
  # procedures. However, the caller should make sure to checkpoint and/or
  # refresh Apparatus afterwards if necessary.
  loadJsonStringIntoProject: (jsonString) ->
    json = JSON.parse(jsonString)
    # TODO: If the file format changes, this will need to check the version
    # and convert or fail appropriately.
    if json.type == "Apparatus"
      @project = @serializer.dejsonify(json)
      @project.performIdempotentCompatibilityFixes()

  # Given a JSON string, parses it and merges novel create panel elements into
  # the editor's project. This does not modify the revision history, so the
  # caller should make sure to checkpoint (and/or refresh Apparatus afterwards)
  # if necessary.
  mergeJsonStringIntoProject: (jsonString) ->
    json = JSON.parse(jsonString)
    # TODO: If the file format changes, this will need to check the version
    # and convert or fail appropriately.
    if json.type == "Apparatus"
      otherProject = @serializer.dejsonify(json)
      for createPanelElement in otherProject.createPanelElements
        if createPanelElement not in @project.createPanelElements
          @project.createPanelElements.push(createPanelElement)

  getJsonStringOfProject: ->
    if not @project
      throw "Trying to get JSON string of nonexistent project"

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
      @loadJsonStringIntoProject(jsonString)
      @checkpoint()
      Apparatus.refresh()  # HACK: calling Apparatus seems funky here.

  mergeFromFile: ->
    Storage.loadFile (jsonString) =>
      @mergeJsonStringIntoProject(jsonString)
      @checkpoint()
      Apparatus.refresh()  # HACK: calling Apparatus seems funky here.


  # ===========================================================================
  # External URL
  # ===========================================================================

  getJsonFromURLPromise: (url) ->
    return fetch(url).then (response) =>
      if not response.ok
        throw "Request for \"#{url}\" failed with code \"#{response.status} #{response.statusText}\""
      return response.text()

  getJsonFromFirebasePromise: (key) ->
    @firebaseAccess ?= new FirebaseAccess()

    @firebaseAccess.loadDrawingPromise(key)
      .then (drawingData) =>
        return drawingData.source

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
  # Export
  # ===========================================================================

  exportSvg: (opts) ->
    svgString = @exportSvgString(opts)
    fileName = @project.editingElement.label + ".svg"
    Storage.saveFile(svgString, fileName, "image/svg+xml;charset=utf-8")

  exportSvgString: (opts={}) ->
    dpi = opts.dpi ? 100
    xMin = opts.xMin ? -6
    xMax = opts.xMax ? 6
    yMin = opts.yMin ? -6
    yMax = opts.yMax ? 6

    # Note we flip vertically so the SVG has the same orientation as what's
    # shown in the Apparatus canvas.
    viewMatrix = new Util.Matrix(dpi, 0, 0, -dpi, -xMin*dpi, yMax*dpi)
    width = (xMax-xMin) * dpi
    height = (yMax-yMin) * dpi

    graphics = @project.editingElement.allGraphics()
    svgString = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"#{width}\" height=\"#{height}\">"
    for graphic in graphics
      svgString += graphic.toSvg({viewMatrix})
    svgString += "</svg>"
    return svgString


  # ===========================================================================
  # Revision History
  # ===========================================================================

  setupRevision: ->
    # @current is a JSON string representing the current state. @undoStack and
    # @redoStack are arrays of such JSON strings.
    @current = @getJsonStringOfProject()
    @undoStack = []
    @redoStack = []
    @maxUndoStackSize = 100

  checkpoint: ->
    return if not @undoStack  # revision history hasn't been set up yet

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
