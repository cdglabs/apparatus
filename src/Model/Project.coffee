_ = require "underscore"
Model = require "./Model"
Dataflow = require "../Dataflow/Dataflow"


module.exports = class Project
  constructor: ->
    initialElement = @createNewElement()

    # Testing
    initialElement.addChild(Model.Rectangle.createVariant())
    initialElement.addChild(Model.Circle.createVariant())

    @editingElement = initialElement
    @selectedParticularElement = null

    @createPanelElements = [
      Model.Rectangle
      Model.Circle
      Model.Text
      initialElement
    ]

    propsToMemoize = [
      "allRelevantAttributes"
      "controlledAttributes"
      "implicitlyControlledAttributes"
      "controllableAttributes"
    ]
    for prop in propsToMemoize
      this[prop] = Dataflow.memoize(this[prop].bind(this))


  # ===========================================================================
  # Selection
  # ===========================================================================

  setEditing: (element) ->
    @editingElement = element
    @selectedParticularElement = null

  select: (particularElement) ->
    if !particularElement
      @selectedParticularElement = null
      return
    @selectedParticularElement = particularElement
    @_expandToElement(particularElement.element)

  _expandToElement: (element) ->
    while element = element.parent()
      element.expanded = true


  # ===========================================================================
  # Create
  # ===========================================================================

  createNewElement: ->
    element = Model.Group.createVariant()
    element.expanded = true
    return element


  # ===========================================================================
  # Memoized attribute sets
  # ===========================================================================

  # An attribute is relevant (should be shown in the outline) if it has a
  # dependency, is depended on, is controlled, or is a variable.
  allRelevantAttributes: ->
    relevantAttributes = []
    for attribute in @editingElement.descendantAttributes()
      # Attributes are relevant if they have a dependency or are depended on.
      referenceAttributes = _.values(attribute.references())
      relevantAttributes.push(attribute) if referenceAttributes.length > 0
      for referenceAttribute in referenceAttributes
        relevantAttributes.push(referenceAttribute)
      # Variables are relevant.
      if attribute.isVariantOf(Model.Variable)
        relevantAttributes.push attribute
    for element in @editingElement.descendantElements()
      # Controlled attributes are relevant.
      relevantAttributes.push(element.controlledAttributes()...)

    return _.unique(relevantAttributes)

  controlledAttributes: ->
    return @selectedParticularElement?.element.controlledAttributes() ? []

  implicitlyControlledAttributes: ->
    return @selectedParticularElement?.element.implicitlyControlledAttributes() ? []

  controllableAttributes: ->
    return @selectedParticularElement?.element.controllableAttributes() ? []
