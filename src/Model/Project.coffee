_ = require "underscore"
Model = require "./Model"


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
      initialElement
    ]


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

  getNextSelected: (hits, isSelectThrough) ->
    # TODO: Needs testing, all the cases. And documentation (with figures?).
    return null unless hits

    if !@selectedParticularElement
      # Second to last or last element.
      return hits[hits.length - 2] ? hits[hits.length - 1]

    deepestHit = _.last(hits)

    if @selectedParticularElement.isAncestorOf(deepestHit)
      if isSelectThrough
        for hit, index in hits
          nextHit = hits[index + 1]
          if nextHit.isEqualTo(@selectedParticularElement)
            return hit
      else
        return @selectedParticularElement

    # Find "deepest sibling"
    for hit, index in hits
      nextHit = hits[index + 1]
      if !nextHit or nextHit.isAncestorOf(@selectedParticularElement)
        return hit

  # ===========================================================================
  # Create
  # ===========================================================================

  createNewElement: ->
    element = Model.Group.createVariant()
    element.expanded = true
    return element
