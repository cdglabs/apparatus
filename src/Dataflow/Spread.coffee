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
          Spread.origins(value.items[0])
      restOfOrigins.push(value.origin)
      return restOfOrigins
    else
      return []
