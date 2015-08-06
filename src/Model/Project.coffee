_ = require "underscore"
Model = require "./Model"


module.exports = class Project
  constructor: ->
    @viewedElement = null
    @selectedParticularElement = null
    @createPanelElements = [
      Model.Rectangle
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

  getNextSelected: (hits, isDoubleClick) ->
    # TODO: Needs testing, all the cases. And documentation (with figures?).
    return null unless hits

    if !@selectedParticularElement
      return hits[1] ? hits[0]

    deepestHit = _.last(hits)

    if @selectedParticularElement.isAncestorOf(deepestHit)
      if isDoubleClick
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
