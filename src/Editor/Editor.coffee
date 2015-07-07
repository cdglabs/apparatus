

class ParticularElement
  constructor: (@element, @spreadIndices) ->


ensureParticularElement = (element) ->
  return element if element instanceof ParticularElement
  return new ParticularElement(element, [])


module.exports = Editor = new class
  constructor: ->

    @viewedElement = null

    @_selectedParticularElement = null
    @_hoveredParticularElement = null
    @_controlledParticularElement = null

  setSelected: (particularElement) ->
    particularElement = ensureParticularElement(particularElement)
    @_selectedParticularElement = particularElement
    @_expandToElement(particularElement.element)

  getSelected: -> @_selectedParticularElement



  _expandToElement: (element) ->
    while element = element.parent()
      element.expanded = true





