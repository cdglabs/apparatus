_ = require "underscore"
numeric = require "numeric"
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
        ref: "HTMLCanvas"
        draw: @_draw
      }

  componentDidMount: ->
    window.addEventListener "resize", @_onResize

  # ===========================================================================
  # Drawing
  # ===========================================================================

  _draw: (ctx) ->
    {project, hoverManager} = @context
    viewMatrix = @_viewMatrix()

    highlight = (graphic) ->
      particularElement = graphic.particularElement
      if hoverManager.controllerParticularElement?.isAncestorOf(particularElement)
        return {color: "#c00", lineWidth: 2.5}
      if project.selectedParticularElement?.isAncestorOf(particularElement)
        return {color: "#09c", lineWidth: 2.5}
      if hoverManager.hoveredParticularElement?.isAncestorOf(particularElement)
        return {color: "#0c9", lineWidth: 2.5}

    renderOpts = {ctx, viewMatrix, highlight}

    @_drawBackgroundGrid(ctx)

    for graphic in @_graphics()
      graphic.render(renderOpts)

    # TODO: draw control points

  _drawBackgroundGrid: (ctx) ->
    {project} = @context

    matrix = project.selectedParticularElement?.contextMatrix()
    matrix ?= new Util.Matrix()

    matrix = @_viewMatrix().compose(matrix)

    ctx.save()
    ctx.beginPath()
    matrix.canvasTransform(ctx)

    for x in [-10 .. 10]
      ctx.moveTo(x, -10)
      ctx.lineTo(x,  10)
    for y in [-10 .. 10]
      ctx.moveTo(-10, y)
      ctx.lineTo( 10, y)

    ctx.restore()

    ctx.save()
    ctx.strokeStyle = "#eee"
    ctx.lineWidth = 0.5
    ctx.stroke()
    ctx.restore()

    ctx.save()
    ctx.beginPath()
    matrix.canvasTransform(ctx)

    ctx.moveTo(-10, 0)
    ctx.lineTo( 10, 0)
    ctx.moveTo(0, -10)
    ctx.lineTo(0,  10)
    ctx.restore()

    ctx.save()
    ctx.strokeStyle = "#ccc"
    ctx.lineWidth = 1
    ctx.stroke()
    ctx.restore()


  # ===========================================================================
  # Event Logic
  # ===========================================================================

  _onMouseDown: (mouseEvent) ->
    mouseEvent.preventDefault()
    Util.clearTextFocus()

    isDoubleClick = @_isDoubleClick()
    @_updateSelected(mouseEvent, isDoubleClick)
    @_updateHoverAndCursor(mouseEvent)
    @_startAppropriateDrag(mouseEvent)

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

  _onResize: ->
    @refs.HTMLCanvas.resize()
    @_rectCached = null

  # ===========================================================================
  # Actions
  # ===========================================================================

  _intent: (mouseEvent) ->
    {project} = @context
    hits = @_hitDetect(mouseEvent)

    selectedParticularElement = project.selectedParticularElement
    selectedElement = selectedParticularElement?.element

    # What to control.
    controller = do ->
      return null unless hits
      for hit in hits
        return hit if hit.element.isController()
      return null

    # What to select if it's a double click.
    nextSelectDouble = do ->
      return null unless hits

      if !selectedParticularElement
        # Second to last or last element.
        return hits[hits.length - 2] ? hits[hits.length - 1]

      # Find "deepest sibling"
      for hit, index in hits
        nextHit = hits[index + 1]
        if !nextHit or nextHit.isAncestorOf(selectedParticularElement)
          return hit

    # What to select if it's a single click.
    nextSelectSingle = do ->
      return null if !nextSelectDouble
      return selectedParticularElement if controller
      if selectedParticularElement?.isAncestorOf(nextSelectDouble)
        return selectedParticularElement
      else
        return nextSelectDouble

    return {controller, nextSelectDouble, nextSelectSingle}

  _updateHoverAndCursor: (mouseEvent) ->
    {hoverManager} = @context
    {controller, nextSelectSingle} = @_intent(mouseEvent)
    hoverManager.hoveredParticularElement = nextSelectSingle
    hoverManager.controllerParticularElement = controller
    # TODO: set cursor

  _updateSelected: (mouseEvent, isDoubleClick) ->
    {project} = @context
    {nextSelectDouble, nextSelectSingle} = @_intent(mouseEvent)
    if isDoubleClick
      project.select(nextSelectDouble)
    else
      project.select(nextSelectSingle)

  _startAppropriateDrag: (mouseDownEvent) ->
    {project} = @context
    {controller, nextSelectSingle} = @_intent(mouseDownEvent)
    particularElementToDrag = controller ? nextSelectSingle
    if particularElementToDrag
      accumulatedMatrix = particularElementToDrag.accumulatedMatrix()
      originalMousePixel = @_mousePosition(mouseDownEvent)
      originalMouseLocal = @_viewMatrix().compose(accumulatedMatrix).toLocal(originalMousePixel)
      @_startDrag(mouseDownEvent, particularElementToDrag, originalMouseLocal)
    else
      @_startPan(mouseDownEvent)

  _startDrag: (mouseDownEvent, particularElementToDrag, originalMouseLocal, startImmediately=false) ->
    {dragManager} = @context

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

    @_startDrag(mouseEvent, newParticularElement, [0, 0], true)

  _startPan: (mouseDownEvent) ->
    {dragManager} = @context
    element = @_editingElement()
    originalMousePixel = @_mousePosition(mouseDownEvent)
    originalMouseLocal = @_viewMatrix().toLocal(originalMousePixel)
    dragManager.start mouseDownEvent,
      onMove: (mouseMoveEvent) =>
        return unless dragManager.drag.consummated
        currentMousePixel = @_mousePosition(mouseMoveEvent)
        currentMouseLocal = @_viewMatrix().toLocal(currentMousePixel)
        offset = numeric.sub(currentMouseLocal, originalMouseLocal)
        element.viewMatrix = element.viewMatrix.translate(offset...)


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
    rect = @_rect()
    x = mouseEvent.clientX - rect.left
    y = mouseEvent.clientY - rect.top
    return [x, y]


  # ===========================================================================
  # Helpers
  # ===========================================================================

  _rect: ->
    return @_rectCached if @_rectCached?
    el = @getDOMNode()
    return @_rectCached = el.getBoundingClientRect()

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
    element = @_editingElement()
    rect = @_rect()
    {width, height} = rect
    screenMatrix = new Util.Matrix(1, 0, 0, -1, width / 2, height / 2)
    elementViewMatrix = element.viewMatrix
    return screenMatrix.compose(elementViewMatrix)
