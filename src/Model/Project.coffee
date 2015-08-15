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

    @allRelevantAttributes = Dataflow.memoize(@allRelevantAttributes.bind(this))


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
  # Relevant attributes
  # ===========================================================================

  # An attribute is relevant (should be shown in the outline) if it has a
  # dependency, is depended on, is controlled, or is a variable.
  allRelevantAttributes: ->
    relevantAttributes = []
    allAttributes = @editingElement.collectAllAttributes()
    allAttributes = _.unique(allAttributes)
    for attribute in allAttributes
      # Attributes are relevant if they have a dependency or are depended on.
      referenceAttributes = _.values(attribute.references())
      relevantAttributes.push(attribute) if referenceAttributes.length > 0
      for referenceAttribute in referenceAttributes
        relevantAttributes.push(referenceAttribute)
      # Variables are always relevant
      if attribute.isVariantOf(Model.Variable)
        relevantAttributes.push attribute
      # TODO: controlled

    return _.unique(relevantAttributes)

