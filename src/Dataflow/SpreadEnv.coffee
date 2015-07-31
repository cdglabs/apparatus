# TODO: This should have tests for isEqualTo and contains


module.exports = class SpreadEnv
  constructor: (@parent, @origin, @index) ->

  lookup: (spread) ->
    if spread.origin == @origin
      return @index
    return @parent?.lookup(spread)

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
