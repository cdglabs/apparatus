###

Why would you want to use Cells? Two reasons:

1. Cells memoize across a single computation.

2. Cells allow you use Spreads.

TODO: Flesh out this documentation.

TODO: Maybe there should be a function that turns a function into a "cell-
ified" function. Sort of like _.memoize but it ties the function in to the
Dataflow system. This is the pattern that Element is using to "cell-ify"
matrix, accumulatedMatrix, etc. Need to think of a good name.


What functions need to be "cellified"?

1. Attribute evaluation. Because the spread values need to be displayed in the
inspector.

2. Accumulated matrix. Because we need to get specific ones out in order to
back compute drag operations.

3. Graphic. Because we need to create the appropriate render tree which
spreads at the Element level.


###


module.exports = Dataflow = {}


# =============================================================================
# Running a computation
# =============================================================================

isComputationRunning = false
computationCounter = 0

Dataflow.run = (callback) ->
  isComputationRunning = true
  computationCounter++
  result = callback()
  isComputationRunning = false
  return result


# =============================================================================
# Context
# =============================================================================

# A Context is created every time a Cell is evaluated. The Context holds
# information for what index we're on for each Spread that is referenced in
# the Cell's fn.

class Dataflow.Context
  constructor: ->
    @spreadToIndex = new Map() # Spread : index, spread must be a root spread.

  assignSpreadIndex: (spread, index) ->
    @spreadToIndex.set(spread.root, index)

  deleteSpread: (spread) ->
    @spreadToIndex.delete(spread.root)

  lookupSpread: (spread) ->
    if @spreadToIndex.has(spread.root)
      return @spreadToIndex.get(spread.root)
    else
      throw new Dataflow.UnresolvedSpreadError(spread)

currentContext = new Dataflow.Context()
currentContext.assignSpreadIndex = ->
  throw "Cannot assign spread index. There is no current computation running."


# =============================================================================
# Cell
# =============================================================================

class Dataflow.Cell
  constructor: (@fn) ->
    @_value = null
    @_lastEvaluated = null

  value: (canReturnSpread=false) ->
    # Ensure that a computation is running.
    if !isComputationRunning
      return Dataflow.run => @value(canReturnSpread)

    if !@_isValid()
      @_value = @_evaluate()
      @_lastEvaluated = computationCounter

    if canReturnSpread
      return @_value
    else
      return @_resolvedValue()

  _isValid: ->
    @_lastEvaluated == computationCounter

  _evaluate: ->
    # Evaluate myself, returning a Spread if my fn returns a Spread.
    previousContext = currentContext
    currentContext = new Dataflow.Context()
    try
      return @_evaluateFn()
    finally
      currentContext = previousContext

  _evaluateFn: ->
    try
      return @fn()
    catch error
      if error instanceof Dataflow.UnresolvedSpreadError
        spread = error.spread
        return @_evaluateAcrossSpread(spread)
      else
        throw error

  _evaluateAcrossSpread: (spread) ->
    resultItems = []
    for index in [0 ... spread.size()]
      currentContext.assignSpreadIndex(spread, index)
      resultItems.push @_evaluateFn()
    currentContext.deleteSpread(spread)
    return new Dataflow.Spread(resultItems, spread.root)

  _resolvedValue: ->
    result = @_value
    while result instanceof Dataflow.Spread
      index = currentContext.lookupSpread(result)
      result = result.items[index]
    return result


# =============================================================================
# Spread
# =============================================================================

class Dataflow.Spread
  constructor: (@items, @root) ->
    if !@root
      @root = this

  size: -> @items.length


class Dataflow.UnresolvedSpreadError
  constructor: (@spread) ->

