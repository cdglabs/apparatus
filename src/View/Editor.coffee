R = require "./R"
Model = require "../Model/Model"
DragManager = require "./Manager/DragManager"
HoverManager = require "./Manager/HoverManager"


R.create "Editor",
  propTypes:
    project: Model.Project

  childContextTypes:
    project: Model.Project
    dragManager: DragManager
    hoverManager: HoverManager

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

      # R.CreatePanelView {}
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
    return @_dragManager ?= new DragManager()

  hoverManager: ->
    return @_hoverManager ?= new HoverManager()
