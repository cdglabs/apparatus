module.exports = class ParticularElement
  constructor: (@element, @spreadIndices) ->

ParticularElement.ensure = (element) ->
  return element if element instanceof ParticularElement
  return new ParticularElement(element, [])
