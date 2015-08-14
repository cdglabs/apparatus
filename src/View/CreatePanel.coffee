R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "CreatePanel",
  contextTypes:
    project: Model.Project

  render: ->
    project = @context.project
    R.div {className: "CreatePanel"},
      R.div {className: "Header"}, "Symbols"
      R.div {className: "Scroller"},
        for element in project.createPanelElements
          R.CreatePanelItem {element, key: Util.getId(element)}

        R.div {className: "CreatePanelAddItem"},
          R.button {
            className: "AddButton",
            onClick: @_createNewElement
          }

  _createNewElement: ->
    project = @context.project
    element = project.createNewElement()
    project.createPanelElements.push(element)
    project.setEditing(element)


R.create "CreatePanelItem",
  contextTypes:
    project: Model.Project
    dragManager: R.DragManager

  propTypes:
    element: Model.Element

  render: ->
    project = @context.project
    element = @props.element
    R.div {
      className: R.cx {
        "CreatePanelItem": true
        "isEditing": element == project.editingElement
      }
    },
      R.div {
        className: "CreatePanelThumbnail"
        onMouseDown: @_onMouseDown
      },
        R.Thumbnail {element}
      # TODO
      # R.div {
      #   className: "CreatePanelItemEditButton icon-pencil"
      #   onClick: @_editElement
      # }
      R.div {
        className: "CreatePanelLabel"
      },
        R.EditableText {
          value: element.label
          setValue: @_setLabelValue
        }

  _setLabelValue: (newValue) ->
    @props.element.label = newValue

  _editElement: ->
    {element} = @props
    {project} = @context
    project.setEditing(element)

  _onMouseDown: (mouseDownEvent) ->
    {dragManager} = @context
    {element} = @props

    mouseDownEvent.preventDefault()
    Util.clearTextFocus()

    dragManager.start mouseDownEvent,
      type: "createElement"
      element: element
      onCancel: =>
        # TODO: remove once there's the pencil icon?
        @_editElement()
      # cursor
