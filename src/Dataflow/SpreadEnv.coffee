module.exports = class SpreadEnv
  constructor: (@parent, @origin, @index) ->

  lookup: (spread) ->
    if spread.origin == @origin
      return @index
    return @parent?.lookup(spread)

  # Note: Not a mutation, assign returns a new SpreadEnv where spread is
  # assigned to index.
  assign: (spread, index) ->
    return new SpreadEnv(this, spread.origin, index)

  indices: ->
    # TODO: Remove
    if @parent
      return @parent.indices().concat(@index)
    else
      return []
