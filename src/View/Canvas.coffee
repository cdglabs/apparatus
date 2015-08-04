_ = require "underscore"
R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"
HoverManager = require "./Manager/HoverManager"


R.create "Canvas",
  contextTypes:
    project: Model.Project
    hoverManager: HoverManager

  render: ->
    R.div {
      className: "Canvas"
      # style:
      #   cursor: @_cursor()
      onMouseDown: @_onMouseDown
      # onMouseEnter: @_onMouseEnter
      # onMouseLeave: @_onMouseLeave
      # onMouseMove: @_onMouseMove
      # onWheel: @_onWheel
    },
      R.HTMLCanvas {
        draw: @_draw
      }

  _draw: (ctx) ->
    project = @context.project
    hoverManager = @context.hoverManager
    element = @_viewedElement()
    viewMatrix = @_viewMatrix()

    highlight = (graphic) ->
      particularElement = graphic.particularElement
      if project.selectedParticularElement?.isAncestorOf(particularElement)
        return {color: "#09c", lineWidth: 2.5}
      if hoverManager.hoveredParticularElement?.isAncestorOf(particularElement)
        return {color: "#0c9", lineWidth: 2.5}

    renderOpts = {ctx, viewMatrix, highlight}

    # TODO: draw background grid

    for graphic in element.allGraphics()
      graphic.render(renderOpts)

    # TODO: draw control points

  _onMouseDown: (mouseDownEvent) ->
    el = @getDOMNode()
    rect = el.getBoundingClientRect()

    x = mouseDownEvent.clientX - rect.left
    y = mouseDownEvent.clientY - rect.top

    # TODO: An optimization would be to save graphics from drawing.

    project = @context.project
    element = @_viewedElement()
    viewMatrix = @_viewMatrix()

    hitDetectOpts = {viewMatrix, x, y}

    hits = null
    for graphic in element.allGraphics()
      hits = graphic.hitDetect(hitDetectOpts) ? hits

    nextSelected = project.getNextSelected(hits, false)

    project.select(nextSelected)

  _viewedElement: ->
    project = @context.project
    element = project.viewedElement
    return element

  _viewMatrix: ->
    el = @getDOMNode()
    rect = el.getBoundingClientRect()
    {width, height} = rect

    return new Util.Matrix(100, 0, 0, -100, width / 2, height / 2)
