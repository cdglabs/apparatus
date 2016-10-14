_ = require "underscore"
numeric = require "numeric"
key = require "keymaster"
R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"
ImageCache = require "../Util/ImageCache"


# "ApparatusCanvas" is a component which shows a rendered Apparatus diagram. It
# is used in four different contexts:
#   EditorCanvas (edit mode, using BareEditorCanvas):
#     the main direct-manipulation region of the Apparatus editor,
#   EditorCanvas (preview mode, using BareViewerCanvas):
#     the full-screen "diagram preview" mode of the Apparatus editor,
#   ThumbnailCanvas:
#     the symbol icons on the left-hand side of the Apparatus editor.
#   BareViewerCanvas:
#     the embeddable Apparatus diagram viewer

R.create "ApparatusCanvas",
  contextTypes:
    project: Model.Project
    hoverManager: R.HoverManager
    dragManager: R.DragManager

  propTypes:
    className: String
    element: Model.Element
    cacheRect: Boolean  # should the element's size / position be cached?

    # display
    screenMatrixScale: Number
    hideGrid: Boolean
    highlightControllers: Boolean
    highlightNonControllers: Boolean
    showControlPoints: Boolean

    # interaction
    enableGeneralInteraction: Boolean
    enableControllerInteraction: Boolean
    enablePanAndZoom: Boolean
    clampMouseWhileDragging: Boolean

  render: ->
    {className, children} = @props

    R.div {
      className: className
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
      children

  componentWillMount: ->
    @_imageCache = new ImageCache()

  componentDidMount: ->
    window.addEventListener "resize", @_onResize

  componentWillUnmount: ->
    window.removeEventListener "resize", @_onResize

  # ===========================================================================
  # Drawing
  # ===========================================================================

  _draw: (ctx) ->
    {element} = @props
    {project, hoverManager} = @context

    highlight = (graphic) =>
      particularElement = graphic.particularElement
      if @props.highlightControllers
        if hoverManager.controllerParticularElement?.isAncestorOf(particularElement)
          return {color: "#c00", lineWidth: 2.5}
      if @props.highlightNonControllers
        if project.selectedParticularElement?.isAncestorOf(particularElement)
          return {color: "#09c", lineWidth: 2.5}
        if hoverManager.hoveredParticularElement?.isAncestorOf(particularElement)
          return {color: "#0c9", lineWidth: 2.5}

    renderOpts = _.extend(@_graphicsOpts(), {ctx, highlight})

    # HACK: This feature should exist but there is currently no way to set
    # isGridHidden in the UI (you can only set it in the console...)
    if not @props.hideGrid and not element.isGridHidden
      @_drawBackgroundGrid(ctx)

    for graphic in @_graphics()
      graphic.render(renderOpts)

    if @props.showControlPoints
      @_drawControlPoints(ctx)

  _drawControlPoints: (ctx) ->
    {hoverManager} = @context
    for controlPoint in @_controlPoints()
      ctx.save()
      ctx.beginPath()
      [x, y] = controlPoint.point
      ctx.arc(x, y, @_controlPointRadius, 0, 2 * Math.PI, false)

      color = "#09c"
      if controlPoint.attributesToChange.length > 0
        if _.intersection(controlPoint.attributesToChange, hoverManager.attributesToChange).length > 0
          color = "#c00"

      ctx.fillStyle = if controlPoint.filled then color else "#fff"
      ctx.fill()
      ctx.strokeStyle = color
      ctx.stroke()

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
  # Control Points
  # ===========================================================================

  # Note: control points are not to be confused with controllers. However, in
  # a future iteration I would like to unify these, so that control points
  # really *are* controllers. This would allow more flexible control points to
  # be developed, for example for manipulating beziers or for creating custom
  # control points for certain elements.

  _controlPointRadius: 5

  _controlPoints: ->
    {project} = @context
    selectedParticularElement = project.selectedParticularElement
    return [] unless selectedParticularElement

    matrix = selectedParticularElement.accumulatedMatrix()
    return [] unless matrix
    matrix = @_viewMatrix().compose(matrix)

    controlPoints = selectedParticularElement.element.controlPoints()
    for controlPoint in controlPoints
      controlPoint.point = matrix.fromLocal(controlPoint.point)

    return controlPoints

  _hitDetectControlPoint: (mouseEvent) ->
    mousePixel = @_mousePosition(mouseEvent)
    controlPoints = @_controlPoints()
    quadrance = @_controlPointRadius * @_controlPointRadius
    for controlPoint in controlPoints
      if Util.quadrance(mousePixel, controlPoint.point) <= quadrance
        return controlPoint
    return null


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

    elementToCreate = dragManager.drag.element
    @_createElement(mouseEvent, elementToCreate)

  _onMouseLeave: (mouseEvent) ->
    # TODO

  _onWheel: (wheelEvent) ->
    if @props.enablePanAndZoom
      wheelEvent.preventDefault()
      @_zoom(wheelEvent)

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
  # Hover and Selection
  # ===========================================================================

  _intent: (mouseEvent) ->
    {element} = @props
    {project} = @context
    selectedParticularElement = project.selectedParticularElement

    hits = @_hitDetect(mouseEvent)

    # Manage the "hovered" attributes of elements:
    element.clearHoveredAttr()
    if hits and hits.length
      for particularElem in hits
        particularElem.element.hoveredAttr()?.setOverrideValue(
          particularElem.spreadEnv.toBooleanSpread())

    controlPoint = @_hitDetectControlPoint(mouseEvent)

    # What to control.
    controller = do ->
      return null if controlPoint
      return null unless hits
      for hit in hits
        return hit if hit.element.isController()
      return null

    # What to select if it's a double click.
    nextSelectDouble = do ->
      return selectedParticularElement if controlPoint
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
      return selectedParticularElement if controller or controlPoint
      if selectedParticularElement?.isAncestorOf(nextSelectDouble)
        return selectedParticularElement
      else
        return nextSelectDouble

    if controlPoint
      attributesToChange = controlPoint.attributesToChange
    else if controller
      attributesToChange = controller.element.attributesToChange()
    else if nextSelectSingle
      attributesToChange = nextSelectSingle.element.attributesToChange()
    else
      attributesToChange = []

    return {controlPoint, controller, nextSelectDouble, nextSelectSingle, attributesToChange}

  _updateHoverAndCursor: (mouseEvent) ->
    {hoverManager} = @context
    {controlPoint, controller, nextSelectSingle, attributesToChange} = @_intent(mouseEvent)

    if @props.enableGeneralInteraction
      hoverManager.hoveredParticularElement = nextSelectSingle

    if @props.enableControllerInteraction
      hoverManager.controllerParticularElement = controller
      hoverManager.attributesToChange = attributesToChange

    # TODO: set cursor

  _updateSelected: (mouseEvent, isDoubleClick) ->
    if @props.enableGeneralInteraction
      {project} = @context
      {nextSelectDouble, nextSelectSingle} = @_intent(mouseEvent)
      if isDoubleClick
        project.select(nextSelectDouble)
      else
        project.select(nextSelectSingle)


  # ===========================================================================
  # Dragging and Creating Elements
  # ===========================================================================

  _startAppropriateDrag: (mouseDownEvent) ->
    {project} = @context
    {controlPoint, controller, nextSelectSingle, attributesToChange} = @_intent(mouseDownEvent)

    if controlPoint
      particularElementToDrag = project.selectedParticularElement
    if @props.enableControllerInteraction
      particularElementToDrag ?= controller
    if @props.enableGeneralInteraction
      particularElementToDrag ?= nextSelectSingle

    if particularElementToDrag
      accumulatedMatrix = particularElementToDrag.accumulatedMatrix()
      originalMousePixel = @_mousePosition(mouseDownEvent)
      originalMouseLocal = @_viewMatrix().compose(accumulatedMatrix).toLocal(originalMousePixel)
      @_startDrag(mouseDownEvent, particularElementToDrag, attributesToChange, originalMouseLocal)
    else if @props.enablePanAndZoom
      @_startPan(mouseDownEvent)

  _startDrag: (mouseDownEvent, particularElementToDrag, attributesToChange, originalMouseLocal, startImmediately=false) ->
    {dragManager} = @context

    dragManager.start mouseDownEvent,
      onMove: (mouseMoveEvent) =>
        return unless startImmediately or dragManager.drag.consummated
        currentMousePixel =
          if @props.clampMouseWhileDragging
            @_clampedMousePosition(mouseMoveEvent)
          else
            @_mousePosition(mouseMoveEvent)
        initialValues = for attribute in attributesToChange
          attribute.valueAt(particularElementToDrag.spreadEnv)
        precisions = for attribute in attributesToChange
          attribute.precision()

        # We're going to assume that, for each of the attributesToChange

        objective = (trialValues) =>
          for attribute, index in attributesToChange
            trialValue = trialValues[index]
            # Note: Here is a mutation within an objective function that
            # really ought to be pure (no side effects). But setting the
            # attributes directly is just the easiest way to test the
            # trialValues. Maybe if this ever becomes a problem we could have
            # the objective "clean up" after itself, setting the attributes
            # back to their original values, to make it pure.
            attribute.setAt(trialValue, particularElementToDrag.spreadEnv)
          trialAccumulatedMatrix = particularElementToDrag.accumulatedMatrix()
          trialMousePixel = @_viewMatrix().compose(trialAccumulatedMatrix).fromLocal(originalMouseLocal)
          error = Util.quadrance(trialMousePixel, currentMousePixel)
          return error

        solvedValues = Util.solve(objective, initialValues)
        for attribute, index in attributesToChange
          solvedValue = solvedValues[index]
          precision = precisions[index]
          # Hold the command key to "snap-drag" to one level coarser
          # precision.
          if key.command
            solvedValue = Util.roundToPrecision(solvedValue, precision - 1)
          solvedValue = Util.toPrecision(solvedValue, precision)
          attribute.setAt(solvedValue, particularElementToDrag.spreadEnv)

    if startImmediately
      dragManager.drag.onMove(mouseDownEvent)

  _createElement: (mouseEvent, elementToCreate) ->
    {element} = @props
    {project} = @context

    parent = element
    newElement = elementToCreate.createVariant()
    parent.addChild(newElement)

    newParticularElement = new Model.ParticularElement(newElement)
    project.select(newParticularElement)

    attributesToChange = newParticularElement.element.attributesToChange()

    @_startDrag(mouseEvent, newParticularElement, attributesToChange, [0, 0], true)


  # ===========================================================================
  # Pan, Zoom and Layout
  # ===========================================================================

  _startPan: (mouseDownEvent) ->
    {element} = @props
    {dragManager} = @context
    originalMousePixel = @_mousePosition(mouseDownEvent)
    originalMouseLocal = @_viewMatrix().toLocal(originalMousePixel)
    dragManager.start mouseDownEvent,
      onMove: (mouseMoveEvent) =>
        return unless dragManager.drag.consummated
        currentMousePixel = @_mousePosition(mouseMoveEvent)
        currentMouseLocal = @_viewMatrix().toLocal(currentMousePixel)
        offset = numeric.sub(currentMouseLocal, originalMouseLocal)
        element.viewMatrix = element.viewMatrix.translate(offset...)

  _zoom: (wheelEvent) ->
    {element} = @props
    scaleFactor = Math.pow(1.001, -wheelEvent.deltaY)
    mousePixel = @_mousePosition(wheelEvent)
    [x, y] = @_viewMatrix().toLocal(mousePixel)

    matrix = element.viewMatrix
    matrix = matrix.translate(x, y)
    matrix = matrix.scale(scaleFactor, scaleFactor)
    matrix = matrix.translate(-x, -y)
    element.viewMatrix = matrix

  # ===========================================================================
  # Hit Detection
  # ===========================================================================

  _hitDetect: (mouseEvent) ->
    viewMatrix = @_viewMatrix()
    [x, y] = @_mousePosition(mouseEvent)

    hitDetectOpts = _.extend(@_graphicsOpts(), {x, y})

    hits = null
    for graphic in @_graphics(true)
      hits = graphic.hitDetect(hitDetectOpts) ? hits

    return hits

  _mousePosition: (mouseEvent) ->
    rect = @_rect()
    x = mouseEvent.clientX - rect.left
    y = mouseEvent.clientY - rect.top
    return [x, y]

  _clampedMousePosition: (mouseEvent) ->
    [x, y] = @_mousePosition(mouseEvent)
    rect = @_rect()
    return [Util.clamp(x, 0, rect.width), Util.clamp(y, 0, rect.height)]


  # ===========================================================================
  # Helpers
  # ===========================================================================

  _rect: ->
    return @_rectCached if @_rectCached? and @props.cacheRect
    el = R.findDOMNode(@)
    return @_rectCached = el.getBoundingClientRect()

  _graphics: (useCached=false) ->
    if useCached and @_cachedGraphics
      return @_cachedGraphics
    {element} = @props
    return @_cachedGraphics = element.allGraphics()

  _viewMatrix: ->
    {element, screenMatrixScale} = @props
    rect = @_rect()
    {width, height} = rect
    screenMatrix = new Util.Matrix(screenMatrixScale, 0, 0, -screenMatrixScale, width / 2, height / 2)
    elementViewMatrix = element.viewMatrix
    return screenMatrix.compose(elementViewMatrix)

  # Common options required for render/hit-detection calls to graphics objects
  _graphicsOpts: ->
    viewMatrix = @_viewMatrix()
    imageCache = @_imageCache
    return {viewMatrix, imageCache}


# EditorCanvas wraps ApparatusCanvas up with whatever else is needed to show the
# editor canvas in the Apparatus editor application. (It will show the diagram
# in edit mode or preview mode, depending on whether full-screen mode is
# selected.)

R.create "EditorCanvas",
  contextTypes:
    editor: Model.Editor
    project: Model.Project

  render: ->
    {editor, project} = @context
    {editingElement} = project
    {layout} = editor

    fullScreenButton =
      if not layout.viewOnly
        R.div {
          className: R.cx
            LayoutMode: true
            FullScreen: layout.fullScreen
            "icon-fullscreen": not layout.fullScreen
            "icon-edit": layout.fullScreen
          onClick: => layout.setFullScreen(not layout.fullScreen)
        }
      else if layout.editLink
        R.a {
          href: editor.urlForEditMode()
          target: "_parent"
          style: {color: "inherit"}
          title: "Load in editor"
        },
          R.div {
            className: R.cx
              LayoutMode: true
              EditLink: true
              "icon-pencil": true
          }

    R.div {className: "EditorCanvas FlexGrow FlexContainer"},
      if layout.fullScreen
        R.BareViewerCanvas {
          element: editingElement
        },
          fullScreenButton
      else
        R.Dropzone {
          className: "EditorCanvasDropzone FlexGrow FlexContainer"
          onDrop: @_onFilesDrop
          disableClick: true
          activeClassName: "dropActive"
          rejectClassName: "dropReject"
          accept: "image/*"
          multiple: false
        },
          R.BareEditorCanvas {
            element: editingElement
          },
            fullScreenButton


  # ===========================================================================
  # File Dropping
  # ===========================================================================

  _onFilesDrop: (files) ->
    if not files[0] then return
    file = files[0]
    reader = new FileReader()
    reader.onloadend = =>
      dataURL = reader.result
      @_createImageElement(dataURL)
    reader.readAsDataURL(file)

  _createImageElement: (dataURL) ->
    {project} = @context
    {editingElement} = project

    newElement = Model.Image.createVariant()
    imageComponent = newElement.childOfType(Model.ImageComponent)
    urlAttribute = imageComponent.getAttributesByName().url
    urlAttribute.setExpression("\"#{dataURL}\"")
    editingElement.addChild(newElement)


# BareEditorCanvas is ApparatusCanvas with settings appropriate for editing a
# diagram.

R.create "BareEditorCanvas",
  render: ->
    R.ApparatusCanvas {
      className: "BareEditorCanvas FlexGrow"
      element: @props.element
      cacheRect: true
      screenMatrixScale: 1
      hideGrid: false
      highlightControllers: true
      highlightNonControllers: true
      showControlPoints: true
      enableGeneralInteraction: true
      enableControllerInteraction: true
      enablePanAndZoom: true
      clampMouseWhileDragging: false
      children: @props.children
    }


# BareEditorCanvas is ApparatusCanvas with settings appropriate for viewing a
# diagram interactively (e.g., in an embedding of the diagram on another page).

R.create "BareViewerCanvas",
  render: ->
    R.ApparatusCanvas {
      className: "BareViewerCanvas FlexGrow"
      element: @props.element
      cacheRect: false
      screenMatrixScale: 1
      hideGrid: true
      highlightControllers: true
      highlightNonControllers: false
      showControlPoints: false
      enableGeneralInteraction: false
      enableControllerInteraction: true
      enablePanAndZoom: false
      clampMouseWhileDragging: true
      children: @props.children
    }


# ThumbnailCanvas is ApparatusCanvas with settings appropriate for viewing a
# non-interactive thumbnail of a diagram (e.g., in the "Symbols" palette).

R.create "ThumbnailCanvas",
  render: ->
    R.ApparatusCanvas {
      className: "ThumbnailCanvas FlexGrow"
      element: @props.element
      cacheRect: true  # no interaction so it's just for size
      screenMatrixScale: 0.1
      hideGrid: true
      highlightControllers: true
      highlightNonControllers: true
      showControlPoints: false
      enableGeneralInteraction: false
      enableControllerInteraction: false
      enablePanAndZoom: false
      clampMouseWhileDragging: false  # irrelevant
    }
