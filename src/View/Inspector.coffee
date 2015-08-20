R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


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
            R.AttributeRow {attribute, key: Util.getId(attribute)}
        R.div {className: "AddVariableRow"},
          R.button {className: "AddButton", onClick: @_addVariable}

      for component in element.components()
        R.ComponentSection {component, key: Util.getId(component)}

  _addVariable: ->
    {element} = @props
    element.addVariable()


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
          R.AttributeRow {attribute, key: Util.getId(attribute)}


# NovelAttributesList is used to show attributes in the Outline.
R.create "NovelAttributesList",
  propTypes:
    element: Model.Element

  contextTypes:
    project: Model.Project

  render: ->
    {element} = @props
    {project} = @context

    R.div {className: "AttributesList"},
      for attribute in element.attributes()
        if attribute.isNovel()
          R.AttributeRow {attribute}
      if element == project.editingElement
        R.div {className: "AddVariableRow"},
          R.button {className: "AddButton Interactive", onClick: @_addVariable}

  _addVariable: ->
    {element} = @props
    element.addVariable()
