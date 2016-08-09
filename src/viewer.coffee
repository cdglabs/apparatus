require "../style/viewer.styl"

_ = require "underscore"
R = require "./View/R"
Model = require "./Model/Model"
Dataflow = require "./Dataflow/Dataflow"
Storage = require "./Storage/Storage"
Util = require "./Util/Util"
NodeVisitor = require "./Util/NodeVisitor"


# ApparatusViewer loads an Apparatus diagram from a saved representation and
# displays it in a DOM node, ready for interaction. To use it from JS, write:
#
#   var myViewer = new ApparatusViewer(options);
#
# Here are required/possible option keys:
#
#   You must provide exactly one of...
#     element: [DOM node]
#       Where to attach the viewer.
#     selector: [string]
#       CSS selector for where (single node) to attach the viewer.
#
#   You must provide exactly one of...
#     projectData: [object]
#       Serialized (but not stringified) data for an Apparatus project.
#     url: [string]
#       URL where JSONified project data can be found (via GET request).
#
#   You must provide...
#     regionOfInterest: [object in format {x: [LO, HI], y: [LO, HI]}]
#       Rectangle in diagram coordinates to determine diagram scale/position.
#       (This rectangle will be fit snuggly into the DOM node provided.)
#
#   You may provide...
#     onRender: [function]
#       Callback to be run after each diagram render operation, with `this`
#       taking the value of the ApparatusViewer.
#
# You can read and write the Apparatus project displayed in `myViewer` using
# `myViewer.project`.
#
# As a convenience, `myViewer.getAttributeByLabel(label)` will grab the
# attribute node in the displayed element with label `label`, provided this
# label is unique.

window.ApparatusViewer = class ApparatusViewer
  constructor: (@options) ->
    # TODO: Add selection of which element to view?
    @_getElement()
    @_getProjectAndLoad()

  _load: ->
    # Now we can actually load the diagram!

    # Use regionOfInterest to compute view matrix:
    {regionOfInterest} = @options
    rect = @element.getBoundingClientRect()
    scaleFactor = Math.min(
      rect.width / (regionOfInterest.x[1] - regionOfInterest.x[0]),
      rect.height / (regionOfInterest.y[1] - regionOfInterest.y[0]))
    matrix = new Util.Matrix()
    matrix = matrix.scale(scaleFactor, scaleFactor)
    matrix = matrix.translate(
      -(regionOfInterest.x[1] + regionOfInterest.x[0])/2,
      -(regionOfInterest.y[1] + regionOfInterest.y[0])/2)
    @project.editingElement.viewMatrix = matrix

    @_render()

    @willRefreshNextFrame = false
    for eventName in refreshEventNames
      window.addEventListener(eventName, => @_refresh())

  _getElement: ->
    if @options.element and @options.selector
      throw "Do not provide both `element` and `selector` as options"

    if @options.element?
      @element = @options.element
    else if @options.selector?
      @element = document.querySelector(@options.selector)
    else
      throw "Either `element` or `selector` must be provided as an option"

  _getProjectAndLoad: ->
    if @options.projectData and @options.url
      throw "Do not provide both `projectData` and `url`"

    if @options.projectData?
      @projectData = @options.projectData
      @_deserializeProjectData()
      @_load()
    else if @options.url?
      xhr = new XMLHttpRequest()
      xhr.onreadystatechange = (e) =>
        if xhr.readyState == 4 and xhr.status == 200
          @projectData = JSON.parse(xhr.responseText)
          @_deserializeProjectData()
          @_load()
      xhr.open("GET", @options.url)
      xhr.send()
    else
      throw "Either `projectData` or `url` must be provided as an option"

  _deserializeProjectData: ->
    serializer = Model.SerializerWithBuiltIns.getSerializer()
    @project = serializer.dejsonify(@projectData)

  _render: ->
    Dataflow.run =>
      R.render(R.Viewer({@project}), @element)
    @options.onRender?.apply(this)

  _refresh: ->
    return if @willRefreshNextFrame
    @willRefreshNextFrame = true
    requestAnimationFrame =>
      @_render()
      @willRefreshNextFrame = false

  getAttributeByLabel: (label) ->
    toReturn = undefined
    foundSome = false
    foundMultiple = false

    nodeVisitor = new NodeVisitor
      linksToFollow: {children: yes}
      onVisit: (node) ->
        if node.isVariantOf(Model.Attribute) and node.label == label
          foundSome = true
          if toReturn
            foundMultiple = true
          toReturn = node
    nodeVisitor.visit(@project.editingElement)
    nodeVisitor.finish()

    if not foundSome
      throw "Found no attributes with label #{label}"
    if foundMultiple
      throw "Found multiple attributes with label #{label}"
    return toReturn


refreshEventNames = [
  "mousedown"
  "mousemove"
  "mouseup"
  "keydown"
  "keyup"
  "scroll"
  "change"
  "wheel"
  "mousewheel"
]
