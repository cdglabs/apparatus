R = require "./R"
Model = require "../Model/Model"


R.create "Editor",
  propTypes:
    project: Model.Project

  childContextTypes:
    project: Model.Project
    dragManager: R.DragManager
    hoverManager: R.HoverManager

  getChildContext: ->
    {
      project: @props.project
      dragManager: @dragManager()
      hoverManager: @hoverManager()
    }

  render: ->
    dragManager = @dragManager()
    cursor = dragManager.drag?.cursor

    R.div {
      className: R.cx {
        CursorOverride: cursor?
      }
      style: {cursor: cursor ? ""}
    },
      # R.DragHintView {}

      R.CreatePanel {}
      R.Outline {}
      R.Inspector {}
      # R.ToolbarView {}
      R.Canvas {}
      # R.EditorCanvasView {shape: State.Editor.topSelected()}

  # componentDidMount: ->
  #   @_setupKeyboardListeners()

  # _setupKeyboardListeners: ->
  #   key "backspace", (e) ->
  #     e.preventDefault()
  #     State.Editor.removeSelectedElement()


  dragManager: ->
    return @_dragManager ?= new R.DragManager()

  hoverManager: ->
    return @_hoverManager ?= new R.HoverManager()
