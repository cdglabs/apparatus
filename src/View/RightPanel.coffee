R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "RightPanel",
  contextTypes:
    editor: Model.Editor
    dragManager: R.DragManager

  _onResizeMouseDown: (mouseDownEvent) ->
    startX = mouseDownEvent.clientX
    layout = @context.editor.layout

    @context.dragManager.start mouseDownEvent,
      cursor: "ew-resize"
      onMove: (moveEvent) =>
        dx = moveEvent.clientX - startX
        startX = moveEvent.clientX
        layout.resizeRightPanel(dx)

  componentDidMount: ->
    @refs.resize.getDOMNode().addEventListener("mousedown", @_onResizeMouseDown)

  render: ->
    layout = @context.editor.layout

    R.div { 
        className: "RightPanel"
        style: {
          width: layout.rightPanelWidth
        }
      },
      R.div { 
        className: "RightResize"
        ref: "resize"
        #onClick: layout.dragRightPanel.bind(layout, 10)
      }
      R.Outline {}
      R.Inspector {}

