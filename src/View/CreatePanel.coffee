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
          R.CreatePanelItem {element}

        R.div {className: "CreatePanelAddItem"},
          R.button {
            className: "AddButton",
            onClick: @_createNewElement
          }


  _createNewElement: ->
    # shape = Model.Group.createVariant()
    # State.Editor.definitions.push(shape)
    # State.Editor.setSelected(shape)
    # shape.setExpanded(true)


R.create "CreatePanelItem",
  contextTypes:
    project: Model.Project

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
      R.div {className: "CreatePanelThumbnail"},
        R.Thumbnail {element}
      R.div {
        className: "CreatePanelItemEditButton icon-pencil"
        onClick: @_editElement
      }
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
    # TODO

  _onMouseDown: ->
    # TODO
