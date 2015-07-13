R = require "./R"
Model = require "../Model/Model"


R.create "Inspector",
  contextTypes:
    project: Model.Project

  render: ->
    project = @context.project
    element = project.selectedParticularElement?.element

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
    element = @props.element

    R.div {className: "InspectorList"},
      R.div {className: "ComponentSection"},
        R.div {className: "ComponentSectionTitle"},
          R.span {},
            "Variables"
        R.div {className: "ComponentSectionContent"},
          for attribute in element.variables()
            R.AttributeRow {attribute}
        R.div {className: "AddVariableRow"},
          R.button {className: "AddButton", onClick: @_addVariable}

      for component in element.components()
        R.ComponentSection {component}

  _addVariable: ->
    @props.element.addVariable()



R.create "ComponentSection",
  propTypes:
    component: Model.Component

  render: ->
    component = @props.component

    R.div {className: "ComponentSection"},
      R.div {className: "ComponentSectionTitle"},
        R.span,
          component.label
      R.div {className: "ComponentSectionContent"},
        for attribute in component.attributes()
          R.AttributeRow {attribute}
