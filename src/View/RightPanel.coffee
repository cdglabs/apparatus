R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "RightPanel",
  contextTypes:
    editor: Model.Editor
    dragManager: R.DragManager

  _onResizeMouseDown: (mouseDownEvent) ->
    layout = @context.editor.layout
    startX = mouseDownEvent.clientX
    startWidth = layout.rightPanelWidth

    @context.dragManager.start mouseDownEvent,
      cursor: "ew-resize"
      onMove: (moveEvent) =>
        dx = moveEvent.clientX - startX
        layout.constraintRightPanelWidth(startWidth - dx)

  render: ->
    layout = @context.editor.layout

    if layout.fullScreen
      return null

    R.div { 
        className: R.cx {
           RightPanel: true
           FullScreen: layout.fullScreen
        }
        style: {
          width: layout.rightPanelWidth
        }
      },
      R.div { 
        className: "RightResize"
        onMouseDown: @_onResizeMouseDown
      }
      R.div { className: "RightPanelContainer" }, 
        R.Outline {}
        R.Inspector {}

