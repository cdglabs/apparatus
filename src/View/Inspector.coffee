R = require "./R"
Editor = require "../Editor/Editor"
Model = require "../Model/Model"


R.create "Inspector",
  render: ->
    element = Editor.getSelected()?.element

    R.div {className: "Inspector"},
      R.div {className: "Header"},
        element?.label ? ""
      R.div {className: "Scroller"},
        if element
          R.FullAttributesList {element}


R.create "FullAttributesList",
  propTypes:
    element: Model.Element

  render: ->
    R.div {className: "InspectorList"},
      R.div {className: "ComponentSection"},
        R.div {className: "ComponentSectionTitle"},
          R.span {},
            "Variables"
      #   R.div {className: "ComponentSectionContent"},
      #     for attribute in @element.attributes()
      #       R.AttributeRowView {attribute}
      #   R.div {className: "AddVariableRow"},
      #     R.button {className: "AddButton", onClick: @_addVariable}


      # for component in @element.components()
      #   R.ComponentSectionView {component}

  _addVariable: ->
    @element.addVariable()


