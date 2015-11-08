_ = require "underscore"
R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "CreatePanel",
  contextTypes:
    project: Model.Project
    editor: Model.Editor

  render: ->
    project = @context.project
    layout = @context.editor.layout

    if layout.fullScreen
      return null

    R.div { className: "CreatePanel" },
      R.div { className: "CreatePanelContainer" },
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
    element = @props.element
    R.div {
      className: R.cx {
        "CreatePanelItem": true
        "isEditing": @_isEditing()
      }
    },
      R.div {
        className: "CreatePanelThumbnail"
        onMouseDown: @_onMouseDown
      },
        R.Thumbnail {element}

      if @_isEditable()
        R.span {},
          R.div {
            className: "CreatePanelItemEditButton icon-pencil"
            onClick: @_editElement
          }
      if @_isEditable() and !@_isEditing()
          R.div {
            className: "CreatePanelItemRemoveButton icon-x"
            onClick: @_remove
          }

      R.div {
        className: "CreatePanelLabel"
      },
        R.EditableText {
          value: element.label
          setValue: @_setLabelValue
        }

  _isEditing: ->
    {element} = @props
    {project} = @context
    return element == project.editingElement

  _isEditable: ->
    {element} = @props
    builtIn = _.values(Model)
    return !_.contains(builtIn, element)

  _setLabelValue: (newValue) ->
    @props.element.label = newValue

  _editElement: ->
    {element} = @props
    {project} = @context
    project.setEditing(element)

  _remove: ->
    {element} = @props
    {project} = @context
    project.createPanelElements = _.without(project.createPanelElements, element)

  _onMouseDown: (mouseDownEvent) ->
    {dragManager} = @context
    {element} = @props

    mouseDownEvent.preventDefault()
    Util.clearTextFocus()

    dragManager.start mouseDownEvent,
      type: "createElement"
      element: element
      onCancel: =>
        if @_isEditable()
          @_editElement()
      # cursor
