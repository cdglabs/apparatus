_ = require "underscore"
Model = require "./Model"


module.exports = class Project
  constructor: ->
    initialDiagram = Model.Group.createVariant()
    initialDiagram.expanded = true

    initialDiagram.addChild(Model.Rectangle.createVariant())
    initialDiagram.addChild(Model.Circle.createVariant())

    @editingElement = initialDiagram
    @selectedParticularElement = null

    @createPanelElements = [
      Model.Rectangle
      Model.Circle
      initialDiagram
    ]

  select: (particularElement) ->
    if !particularElement
      @selectedParticularElement = null
      return
    particularElement = Model.ParticularElement.ensure(particularElement)
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
