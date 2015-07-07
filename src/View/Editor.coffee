R = require "./R"
Editor = require "../Editor/Editor"


R.create "Editor",
  render: ->
    R.div {
      # className: R.cx {
      #   CursorOverride: State.UI.globalCursor?
      # }
      # style: {cursor: State.UI.globalCursor ? ""}
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
