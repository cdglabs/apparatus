Model = require "./Model"


module.exports = class Project
  constructor: ->

    @viewedElement = null

    @selectedParticularElement = null

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
