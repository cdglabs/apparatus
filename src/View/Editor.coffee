R = require "./R"


R.create "Editor",
  render: ->
    cursor = R.DragManager.drag?.cursor

    R.div {
      className: R.cx {
        CursorOverride: cursor?
      }
      style: {cursor: cursor ? ""}
    },
      # R.DragHintView {}

      # R.CreatePanelView {}
      R.Outline {}
      R.Inspector {}
      # R.ToolbarView {}
      # R.EditorCanvasView {shape: State.Editor.topSelected()}

  # componentDidMount: ->
  #   @_setupKeyboardListeners()

  # _setupKeyboardListeners: ->
  #   key "backspace", (e) ->
  #     e.preventDefault()
  #     State.Editor.removeSelectedElement()
