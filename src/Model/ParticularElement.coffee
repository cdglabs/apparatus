Util = require "../Util/Util"


module.exports = class ParticularElement
  constructor: (@element, @indices) ->

  isEqualTo: (particularElement) ->
    return @element == particularElement.element and
      _.isEqual(@indices, particularElement.indices)

  isAncestorOf: (particularElement) ->
    return @element.isAncestorOf(particularElement.element) and
      Util.startsWith(particularElement.indices, @indices)


ParticularElement.ensure = (element) ->
  return element if element instanceof ParticularElement
  return new ParticularElement(element, [])
