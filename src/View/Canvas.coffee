_ = require "underscore"
R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "Canvas",
  contextTypes:
    project: Model.Project
    hoverManager: R.HoverManager
    dragManager: R.DragManager

  render: ->
    R.div {
      className: "Canvas"
      # style:
      #   cursor: @_cursor()
      onMouseDown: @_onMouseDown
      onMouseEnter: @_onMouseEnter
      onMouseLeave: @_onMouseLeave
      onMouseMove: @_onMouseMove
      onWheel: @_onWheel
    },
      R.HTMLCanvas {
        draw: @_draw
      }

  # ===========================================================================
  # Drawing
  # ===========================================================================

  _draw: (ctx) ->
    project = @context.project
    hoverManager = @context.hoverManager
    element = @_editingElement()
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


  # ===========================================================================
  # Event Logic
  # ===========================================================================

  _onMouseDown: (mouseEvent) ->
    # TODO: Determine whether it was a double click and set isSelectThrough
    # appropriately.
    @_updateSelected(mouseEvent, false)
    @_startDrag(mouseEvent)

  _onMouseMove: (mouseEvent) ->
    dragManager = @context.dragManager
    if !dragManager.drag
      @_updateHoverAndCursor(mouseEvent)

  _onMouseEnter: (mouseEvent) ->
    # TODO

  _onMouseLeave: (mouseEvent) ->
    # TODO

  _onWheel: (wheelEvent) ->
    # TODO

  # ===========================================================================
  # Actions
  # ===========================================================================

  _updateHoverAndCursor: (mouseEvent) ->
    {hoverManager, project} = @context
    hits = @_hitDetect(mouseEvent)
    nextSelected = project.getNextSelected(hits, false)
    hoverManager.hoveredParticularElement = nextSelected
    # TODO: Deal with controlled elements, set cursor

  _updateSelected: (mouseEvent, isSelectThrough) ->
    project = @context.project
    hits = @_hitDetect(mouseEvent)
    nextSelected = project.getNextSelected(hits, isSelectThrough)
    project.select(nextSelected)

  _startDrag: (mouseDownEvent) ->
    {project, dragManager} = @context

    # TODO: Deal with controlled elements
    particularElementToDrag = project.selectedParticularElement
    return unless particularElementToDrag

    attributesToChange = particularElementToDrag.element.attributesToChange()
    viewMatrix = @_viewMatrix()
    accumulatedMatrix = particularElementToDrag.accumulatedMatrix()
    originalMousePixel = @_mousePosition(mouseDownEvent)
    originalMouseLocal = viewMatrix.compose(accumulatedMatrix).toLocal(originalMousePixel)

    dragManager.start mouseDownEvent,
      onMove: (mouseMoveEvent) =>
        return unless dragManager.drag.consummated
        currentMousePixel = @_mousePosition(mouseMoveEvent)
        initialValues = for attribute in attributesToChange
          attribute.value()
        precisions = for attribute in attributesToChange
          Util.precision(attribute.exprString)

        objective = (trialValues) =>
          for attribute, index in attributesToChange
            trialValue = trialValues[index]
            # Note: Here is a mutation within an objective function that
            # really ought to be pure (no side effects). But setting the
            # attributes directly is just the easiest way to test the
            # trialValues. Maybe if this ever becomes a problem we could have
            # the objective "clean up" after itself, setting the attributes
            # back to their original values, to make it pure.
            attribute.setExpression(trialValue)
          trialAccumulatedMatrix = particularElementToDrag.accumulatedMatrix()
          trialMousePixel = viewMatrix.compose(trialAccumulatedMatrix).fromLocal(originalMouseLocal)
          error = Util.quadrance(trialMousePixel, currentMousePixel)
          return error

        solvedValues = Util.solve(objective, initialValues)
        for attribute, index in attributesToChange
          solvedValue = solvedValues[index]
          precision = precisions[index]
          solvedValue = Util.toPrecision(solvedValue, precision)
          attribute.setExpression(solvedValue)


  # ===========================================================================
  # Hit Detection
  # ===========================================================================

  _hitDetect: (mouseEvent) ->
    element = @_editingElement()
    viewMatrix = @_viewMatrix()
    [x, y] = @_mousePosition(mouseEvent)

    hitDetectOpts = {viewMatrix, x, y}

    hits = null
    # TODO: An optimization would be to save graphics from drawing.
    for graphic in element.allGraphics()
      hits = graphic.hitDetect(hitDetectOpts) ? hits

    return hits

  _mousePosition: (mouseEvent) ->
    el = @getDOMNode()
    rect = el.getBoundingClientRect()
    x = mouseEvent.clientX - rect.left
    y = mouseEvent.clientY - rect.top
    return [x, y]


  # ===========================================================================
  # Helpers
  # ===========================================================================

  _editingElement: ->
    project = @context.project
    element = project.editingElement
    return element

  _viewMatrix: ->
    el = @getDOMNode()
    rect = el.getBoundingClientRect()
    {width, height} = rect
    return new Util.Matrix(100, 0, 0, -100, width / 2, height / 2)
