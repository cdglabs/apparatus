R = require "./R"
Model = require "../Model/Model"


R.create "Editor",
  propTypes:
    project: Model.Project

  childContextTypes:
    project: Model.Project

  getChildContext: ->
    {project: @props.project}

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
