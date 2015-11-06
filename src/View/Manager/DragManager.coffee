_ = require "underscore"

###

These are the options you can pass in to DragManager.start:

    cursor: (String) Sets the global cursor for the duration of the drag
    gesture.

    onConsummate(mouseMoveEvent): Will be called once the user has moved the
    mouse 3 pixels from the initial mouse down location.

    onMove(mouseMoveEvent): Will be called repeatedly, every time the mouse
    moves after the drag has been consummated.

    onDrop(mouseUpEvent): Will be called once the user releases the object being
    dragged.

    onCancel(mouseUpEvent): Will be called if the user releases the object
    without ever consummating the drag.

###

module.exports = class DragManager
  constructor: ->
    @drag = null
    window.addEventListener("mousemove", @_onMouseMove)
    window.addEventListener("mouseup", @_onMouseUp)

  start: (mouseDownEvent, spec) ->
    @drag = new Drag(mouseDownEvent, spec)

  _onMouseMove: (mouseMoveEvent) =>
    return unless @drag
    if !@drag.consummated
      # Check if we should consummate.
      dx = mouseMoveEvent.clientX - @drag.originalX
      dy = mouseMoveEvent.clientY - @drag.originalY
      d  = Math.max(Math.abs(dx), Math.abs(dy))
      if d > 3
        @_consummate(mouseMoveEvent)
    else
      @drag.onMove?(mouseMoveEvent)

  _onMouseUp: (mouseUpEvent) =>
    return unless @drag
    if @drag.consummated
      @drag.onDrop?(mouseUpEvent)
    else
      @drag.onCancel?(mouseUpEvent)
    @drag.onUp?(mouseUpEvent)
    @drag = null

  _consummate: (mouseMoveEvent) ->
    @drag.consummated = true
    @drag.onConsummate?(mouseMoveEvent)


class Drag
  constructor: (mouseDownEvent, spec) ->
    _.extend(this, spec)
    @originalX = mouseDownEvent.clientX
    @originalY = mouseDownEvent.clientY
    @consummated ?= false
