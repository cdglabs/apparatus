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
          R.FullAttributesList {element, context: "Inspector"}


R.create "FullAttributesList",
  propTypes:
    element: Model.Element
    context: ["Outline", "Inspector"]

  render: ->
    {element, context} = @props

    R.div {className: "InspectorList"},
      R.div {className: "ComponentSection"},
        R.div {className: "ComponentSectionTitle"},
          R.span {},
            "Variables"
        R.div {className: "ComponentSectionContent"},
          R.VariablesList {element, context},
        R.div {className: "AddVariableRow"},
          R.button {className: "AddButton", onClick: @_addVariable}

      for component in element.components()
        R.ComponentSection {element, component, key: Util.getId(component), context}

  _addVariable: ->
    {element} = @props
    element.addVariable()


R.create "VariablesList",
  propTypes:
    element: Model.Element
    context: ["Outline", "Inspector"]

  mixins: [R.AnnotateMixin]

  render: ->
    {element, context} = @props

    R.div {className: "VariablesList"},
      for attribute in element.variables()
        R.AttributeRow {attribute, key: Util.getId(attribute), context}

  annotation: ->
    # Used for drag reording.
    {element: @props.element, context: @props.context}


R.create "ComponentSection",
  propTypes:
    component: Model.Component
    context: ["Outline", "Inspector"]

  render: ->
    {component, context} = @props

    R.div {className: "ComponentSection"},
      R.div {className: "ComponentSectionTitle"},
        R.span,
          component.label
      R.div {className: "ComponentSectionContent"},
        for attribute in component.attributes()
          R.AttributeRow {attribute, key: Util.getId(attribute), context}


# NovelAttributesList is used to show attributes in the Outline. A design
# question is what attributes should be shown? We want to show anything that
# you might want to reference in another expression, and anything that might
# be useful in understanding a diagram (so that the outline is like the source
# code of the diagram). Currently we show any attribute from a component that
# is novel and all variables.
R.create "NovelAttributesList",
  propTypes:
    element: Model.Element
    context: ["Outline", "Inspector"]

  contextTypes:
    project: Model.Project

  mixins: [R.AnnotateMixin]

  render: ->
    {element, context} = @props
    {project} = @context

    R.div {className: "AttributesList"},
      for attribute, i in element.allAttributes()
        shouldShow = attribute.isNovel() or attribute.isVariantOf(Model.Variable)
        if shouldShow
          R.AttributeRow {key: Util.getId(attribute), attribute, context}
      if element == project.editingElement
        R.div {className: "AddVariableRow"},
          R.button {className: "AddButton Interactive", onClick: @_addVariable}

  _addVariable: ->
    {element} = @props
    element.addVariable()

  annotation: ->
    # Used for drag reording.
    {element: @props.element, context: @props.context}
