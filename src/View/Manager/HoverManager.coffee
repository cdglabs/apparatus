module.exports = class HoverManager
  constructor: ->
    @hoveredParticularElement = null
    @controllerParticularElement = null
    @attributesToChange = []
    @hoveredAttribute = null
