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
    {project, hoverManager} = @context
    viewMatrix = @_viewMatrix()

    highlight = (graphic) ->
      particularElement = graphic.particularElement
      if project.selectedParticularElement?.isAncestorOf(particularElement)
        return {color: "#09c", lineWidth: 2.5}
      if hoverManager.hoveredParticularElement?.isAncestorOf(particularElement)
        return {color: "#0c9", lineWidth: 2.5}

    renderOpts = {ctx, viewMatrix, highlight}

    # TODO: draw background grid

    for graphic in @_graphics()
      graphic.render(renderOpts)

    # TODO: draw control points


  # ===========================================================================
  # Event Logic
  # ===========================================================================

  _onMouseDown: (mouseEvent) ->
    mouseEvent.preventDefault()
    Util.clearTextFocus()

    isDoubleClick = @_isDoubleClick()
    @_updateSelected(mouseEvent, isDoubleClick)
    @_updateHoverAndCursor(mouseEvent)
    @_startDrag(mouseEvent)

  _onMouseMove: (mouseEvent) ->
    dragManager = @context.dragManager
    if !dragManager.drag
      @_updateHoverAndCursor(mouseEvent)

  _onMouseEnter: (mouseEvent) ->
    {dragManager} = @context
    return unless dragManager.drag?.type == "createElement"

    element = dragManager.drag.element
    @_createElement(mouseEvent, element)

  _onMouseLeave: (mouseEvent) ->
    # TODO

  _onWheel: (wheelEvent) ->
    # TODO

  _isDoubleClick: ->
    doubleClickThreshold = 400
    @_lastMouseDownTime ?= 0
    currentTime = Date.now()
    isDoubleClick = (currentTime - @_lastMouseDownTime < doubleClickThreshold)
    @_lastMouseDownTime = currentTime
    return isDoubleClick

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

  _startDrag: (mouseDownEvent, startImmediately=null) ->
    {project, dragManager} = @context


    if startImmediately
      particularElementToDrag = startImmediately.particularElementToDrag
      originalMouseLocal = startImmediately.originalMouseLocal
    else
      # TODO: Deal with controlled elements
      particularElementToDrag = project.selectedParticularElement
      return unless particularElementToDrag
      accumulatedMatrix = particularElementToDrag.accumulatedMatrix()
      originalMousePixel = @_mousePosition(mouseDownEvent)
      originalMouseLocal = @_viewMatrix().compose(accumulatedMatrix).toLocal(originalMousePixel)

    attributesToChange = particularElementToDrag.element.attributesToChange()

    dragManager.start mouseDownEvent,
      onMove: (mouseMoveEvent) =>
        return unless startImmediately or dragManager.drag.consummated
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
          trialMousePixel = @_viewMatrix().compose(trialAccumulatedMatrix).fromLocal(originalMouseLocal)
          error = Util.quadrance(trialMousePixel, currentMousePixel)
          return error

        solvedValues = Util.solve(objective, initialValues)
        for attribute, index in attributesToChange
          solvedValue = solvedValues[index]
          precision = precisions[index]
          solvedValue = Util.toPrecision(solvedValue, precision)
          attribute.setExpression(solvedValue)

    if startImmediately
      dragManager.drag.onMove(mouseDownEvent)

  _createElement: (mouseEvent, element) ->
    {project} = @context

    parent = @_editingElement()
    newElement = element.createVariant()
    parent.addChild(newElement)

    newParticularElement = new Model.ParticularElement(newElement)
    project.select(newParticularElement)

    @_startDrag(mouseEvent, {
      particularElementToDrag: newParticularElement
      originalMouseLocal: [0, 0]
    })


  # ===========================================================================
  # Hit Detection
  # ===========================================================================

  _hitDetect: (mouseEvent) ->
    viewMatrix = @_viewMatrix()
    [x, y] = @_mousePosition(mouseEvent)

    hitDetectOpts = {viewMatrix, x, y}

    hits = null
    for graphic in @_graphics(true)
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

  _graphics: (useCached=false) ->
    if useCached and @_cachedGraphics
      return @_cachedGraphics
    element = @_editingElement()
    return @_cachedGraphics = element.allGraphics()

  _viewMatrix: ->
    el = @getDOMNode()
    rect = el.getBoundingClientRect()
    {width, height} = rect
    return new Util.Matrix(100, 0, 0, -100, width / 2, height / 2)
