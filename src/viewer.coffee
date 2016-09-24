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
# Providing `onRender` is one tool for hooking external Javascript code into an
# embedded Apparatus diagram. The other most important tool is
# `ApparatusViewer::getAttributeByLabel`. See documentation on that below.

window.ApparatusViewer = class ApparatusViewer
  constructor: (@options) ->
    # TODO: Add selection of which element to view?
    @_getElement()
    @_getProjectAndLoad()

  # Returns an object representing the attribute node with label `label`,
  # provided this label is unique. The object returned is an
  # `ApparatusViewer.Attribute`. See methods on that class to see what you can
  # do with it.
  getAttributeByLabel: (label) ->
    attribute = undefined
    foundSome = false
    foundMultiple = false

    nodeVisitor = new NodeVisitor
      linksToFollow: {children: yes}
      onVisit: (node) ->
        if node.isVariantOf(Model.Attribute) and node.label == label
          foundSome = true
          if attribute
            foundMultiple = true
          attribute = node
    nodeVisitor.visit(@_project.editingElement)
    nodeVisitor.finish()

    if not foundSome
      throw "Found no attributes with label #{label}"
    if foundMultiple
      throw "Found multiple attributes with label #{label}"
    return new Attribute(attribute)

  # ADVANCED USAGE: Returns a reference to the internal `Project` object being
  # displayed in the viewer. You can read and write to this object, but beware:
  # its representation and behavior are subject to change.
  rawProject: ->
    return @_project

  _getElement: ->
    if @options.element and @options.selector
      throw "Do not provide both `element` and `selector` as options"

    if @options.element?
      @_element = @options.element
    else if @options.selector?
      @_element = document.querySelector(@options.selector)
    else
      throw "Either `element` or `selector` must be provided as an option"

  _getProjectAndLoad: ->
    if @options.projectData and @options.url
      throw "Do not provide both `projectData` and `url`"

    if @options.projectData?
      @_projectData = @options.projectData
      @_deserializeProjectData()
      @_load()
    else if @options.url?
      xhr = new XMLHttpRequest()
      xhr.onreadystatechange = (e) =>
        if xhr.readyState == 4 and xhr.status == 200
          @_projectData = JSON.parse(xhr.responseText)
          @_deserializeProjectData()
          @_load()
      xhr.open("GET", @options.url)
      xhr.send()
    else
      throw "Either `projectData` or `url` must be provided as an option"

  _load: ->
    # Now we can actually load the diagram!

    # Use regionOfInterest to compute view matrix:
    {regionOfInterest} = @options
    rect = @_element.getBoundingClientRect()
    scaleFactor = Math.min(
      rect.width / (regionOfInterest.x[1] - regionOfInterest.x[0]),
      rect.height / (regionOfInterest.y[1] - regionOfInterest.y[0]))
    matrix = new Util.Matrix()
    matrix = matrix.scale(scaleFactor, scaleFactor)
    matrix = matrix.translate(
      -(regionOfInterest.x[1] + regionOfInterest.x[0])/2,
      -(regionOfInterest.y[1] + regionOfInterest.y[0])/2)
    @_project.editingElement.viewMatrix = matrix

    @_render()

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

    @willRefreshNextFrame = false
    for eventName in refreshEventNames
      window.addEventListener(eventName, => @_refresh())

  _deserializeProjectData: ->
    serializer = Model.SerializerWithBuiltIns.getSerializer()
    @_project = serializer.dejsonify(@_projectData)

  _render: ->
    Dataflow.run =>
      R.render(R.Viewer({project: @_project}), @_element)
    @options.onRender?.apply(this)

  _refresh: ->
    return if @willRefreshNextFrame
    @willRefreshNextFrame = true
    requestAnimationFrame =>
      @_render()
      @willRefreshNextFrame = false


ApparatusViewer.Attribute = class Attribute
  constructor: (@_attribute) ->

  # Returns the current value of the attribute.
  value: ->
    @_attribute.value()

  # Sets the defining expression of the attribute to the string given.
  setExpression: (exprString) ->
    @_attribute.setExpression(exprString)
    return

  # ADVANCED USAGE: Returns a reference to the internal `Attribute` node
  # represented by this object. You can read and write to this object, but
  # beware: its representation and behavior are subject to change.
  raw: ->
    @_attribute
