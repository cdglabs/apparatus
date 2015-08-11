R = require "./R"
Model = require "../Model/Model"


R.create "Editor",
  propTypes:
    project: Model.Project

  childContextTypes:
    project: Model.Project
    dragManager: R.DragManager
    hoverManager: R.HoverManager

  componentWillMount: ->
    @_dragManager = new R.DragManager()
    @_hoverManager = new R.HoverManager()

  getChildContext: ->
    {
      project: @props.project
      dragManager: @_dragManager
      hoverManager: @_hoverManager
    }

  render: ->
    cursor = @_dragManager.drag?.cursor

    R.div {
      className: R.cx {
        CursorOverride: cursor?
      }
      style: {cursor: cursor ? ""}
    },
      R.DragHint {}

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



R.create "ContextWrapper",
  propTypes:
    childRender: Function
    context: Object

  childContextTypes:
    project: Model.Project
    dragManager: R.DragManager
    hoverManager: R.HoverManager

  getChildContext: ->
    @props.context

  render: -> @props.childRender()



R.create "DragHint",
  contextTypes:
    dragManager: R.DragManager

  render: ->
    {dragManager} = @context

    drag = dragManager.drag

    R.div {className: "DragHintContainer"},
      if drag?.type == "transcludeAttribute" and drag.consummated
        R.div {
          className: "DragHint"
          style:
            left: drag.x + 5
            top:  drag.y + 5
        },
          R.AttributeToken {attribute: drag.attribute}


