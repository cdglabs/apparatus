_ = require "underscore"


module.exports = class Spread
  constructor: (@items, @origin) ->

  # Recursively converts a spread to an array. So if I'm a nested spread,
  # toArray will return a nested array.
  toArray: ->
    _.map @items, (item) ->
      if item instanceof Spread
        item.toArray()
      else
        item

  flattenToArray: ->
    _.flatten(@toArray())

  # Given a value, returns an array of its spread-origins (if it's a spread) or
  # [] (otherwise). Assumes that spreads are homogeneous.
  @origins: (value) ->
    if value instanceof Spread
      restOfOrigins =
        if value.items.length == 0
          []
        else
          bestRestOfOrigins = []
          for item in value.items
            curRestOfOrigins = Spread.origins(item)
            if curRestOfOrigins.length > bestRestOfOrigins.length
              bestRestOfOrigins = curRestOfOrigins
          bestRestOfOrigins
      restOfOrigins.unshift(value.origin)
      return restOfOrigins
    else
      return []

  isSpreadAlongOrigin: (someOrigin) ->
    # We will assume, with fairly good reason, that a spread is homogeneous.
    return (
      (@origin == someOrigin) or
      (@items.length > 0 and @items[0] instanceof Spread and @items[0].isSpreadAlongOrigin(someOrigin))
    )

  mapSingleLevel: (f) ->
    return new Spread(@items.map(f), @origin)

  setAt: (value, spreadEnv) ->
    index = spreadEnv.lookup(@)
    item = @items[index]
    if item instanceof Spread
      item.setAt(value, spreadEnv)
    else
      @items[index] = value

  cloneSingleLevel: () ->
    new Spread(@items.slice(), @origin)

Spread.reshapeLike = (spread, otherSpread, defaultValue = 0) ->
  if not (spread instanceof Spread)
    if not (otherSpread instanceof Spread)
      return spread
    else  # otherSpread instanceof Spread
      return otherSpread.mapSingleLevel (otherItem) ->
        Spread.reshapeLike(spread, otherItem, defaultValue)
  else  # spread instanceof Spread
    if spread.origin == otherSpread.origin
      return otherSpread.mapSingleLevel (otherItem, i) ->
        Spread.reshapeLike(spread.items[i] ? defaultValue, otherItem)
    else  # spread.origin != otherSpread.origin
      if otherSpread.isSpreadAlongOrigin(spread.origin)
        # don't throw out this layer of spread;
        # instead, map over first layer of otherSpread so we can get closer
        # to getting spread.origin as the origin on both sides
        return otherSpread.mapSingleLevel (otherItem) ->
          Spread.reshapeLike(spread, otherItem, defaultValue)
      else
        # throw out this layer of spread
        # TODO: what's up with empty spread.items?
        return Spread.reshapeLike(spread.items[0], otherSpread, defaultValue)
