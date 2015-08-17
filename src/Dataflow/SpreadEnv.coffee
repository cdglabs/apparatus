Spread = require "./Spread"

# TODO: This should have tests for isEqualTo and contains

module.exports = class SpreadEnv
  constructor: (@parent, @origin, @index) ->

  lookup: (spread) ->
    if spread.origin == @origin
      return @index
    return @parent?.lookup(spread)

  # If value is a spread, resolve will recursively try to lookup an index and
  # return the item at that index.
  resolve: (value) ->
    if value instanceof Spread
      index = @lookup(value)
      if index?
        value = value.items[index]
        return @resolve(value)
    return value

  # Like resolve, but will take index 0 if the spread cannot be found.
  resolveWithDefault: (value) ->
    if value instanceof Spread
      index = @lookup(value) ? 0
      value = value.items[index]
      return @resolveWithDefault(value)
    return value


  # Note: assign is not a mutation, it returns a new SpreadEnv where spread is
  # assigned to index.
  assign: (spread, index) ->
    return new SpreadEnv(this, spread.origin, index)

  isEqualTo: (spreadEnv) ->
    return false unless spreadEnv?
    return false unless @origin == spreadEnv.origin and @index == spreadEnv.index
    return true if !@parent and !spreadEnv.parent
    return @parent.isEqualTo(spreadEnv.parent)

  contains: (spreadEnv) ->
    return false unless spreadEnv?
    return true if @isEqualTo(spreadEnv)
    return @contains(spreadEnv.parent)


SpreadEnv.empty = new SpreadEnv()
