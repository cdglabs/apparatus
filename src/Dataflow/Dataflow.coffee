###

# Introduction


# Cells

A Cell is like a data cell in a spreadsheet. You construct them by passing in
a function which computes the value. For example:

    a = new Dataflow.Cell(-> 4)
    b = new Dataflow.Cell(-> a.value() * 2)

When you construct a Cell, these are your responsibilities:

1. The Cell's function should be pure. That is, if you call the function
multiple times it should always return the same value. The function should
have no side effects.

2. If the function changes then you must call the cell's invalidate() method.
For example, a function might change because you manually change the cell's fn
property or because the function is closed over a variable that changes.

However, you are not responsible for calling invalidate if the cell references
another cell and the referenced one changes. The Dataflow module takes care of
this dependency tracking.

For example:

    a.fn = -> 22
    a.invalidate() # Must call this.
    # Don't need to call b.invalidate().

You must call a.invalidate() because you changed a's fn. But you do not need
to call b.invalidate(). Dataflow keeps track of dependencies between cells and
will automatically call b.invalidate() for you.


# Dependency Tracking implementation

Whenever a Cell's value method is called, while running the Cell's fn,
Dataflow logs any other Cell's whose value method is called. It then saves
dependency links appropriately. This dynamic dependency tracking
implementation strategy is inspired by [Meteor's Tracker][meteor], though it's
used for cache invalidation and keeping track of context (see Spreads below)
rather than Meteor's reactive re-execution of "stale" functions.

[meteor]: https://github.com/meteor/meteor/wiki/Tracker-Manual


# Spreads



###




module.exports = Dataflow = {}



class Dataflow.UnresolvedSpreadError
  constructor: (@spread) ->



class Dataflow.Context
  constructor: ->

  currentCell: ->
    if @cell
      return @cell
    else if @parent
      return @parent.currentCell()
    else
      return null

  spreadIndex: (spread) ->
    if @spread == spread
      return @index
    else if @parent
      return @parent.spreadIndex(spread)
    else
      throw new Dataflow.UnresolvedSpreadError(spread)

class Dataflow.SpreadContext extends Dataflow.Context
  constructor: (@parent, @spread, @index) ->

class Dataflow.CellContext extends Dataflow.Context
  constructor: (@parent, @cell) ->



Dataflow.Evaluator = new class
  constructor: ->
    @currentContext = new Dataflow.Context()

  evaluateCell: (cell) ->
    @currentContext = new Dataflow.CellContext(@currentContext, cell)

    # We remove all dependencies from cell because the proper ones will be
    # added when cell.fn is run.
    Dataflow.removeAllDependencies(cell)

    try
      return cell.fn()
    catch error
      if error instanceof Dataflow.UnresolvedSpreadError
        spread = error.spread
        return @evaluateCellWithSpread(cell, spread)
      else
        throw error
    finally
      @currentContext = @currentContext.parent

  evaluateCellWithSpread: (cell, spread) ->
    rootSpread = spread.root()
    resultItems = []
    for index in [0 ... rootSpread.items.length]
      @currentContext = new Dataflow.SpreadContext(@currentContext, rootSpread, index)
      resultItems.push @evaluateCell(cell)
      @currentContext = @currentContext.parent
    return new Dataflow.Spread(resultItems, spread)

  spreadIndex: (spread) ->
    return @currentContext.spreadIndex(spread.root())

  logRetrieval: (cell) ->
    dependency = cell
    dependent = @currentContext.currentCell()

    if dependent
      Dataflow.addDependency(dependent, dependency)



class Dataflow.Cell
  constructor: (@fn) ->
    @_value = null
    @_isInvalid = true
    @_dependencies = new Set() # Cell
    @_dependents = new Set() # Cell

  value: (canReturnSpread=false) ->
    Dataflow.Evaluator.logRetrieval(this)

    if @_isInvalid
      @_value = Dataflow.Evaluator.evaluateCell(this)
      @_isInvalid = false

    if canReturnSpread
      return @_value
    else
      result = @_value
      while result instanceof Dataflow.Spread
        index = Dataflow.Evaluator.spreadIndex(result)
        result = result.items[index]
      return result

  invalidate: ->
    if Dataflow.Evaluator.currentContext.parent?
      console.log this
      throw "Cannot invalidate a Cell during a computation."

    @_isInvalid = true

    # Need to tell every cell that depends on me that it is now invalid.
    @_dependents.forEach (cell) =>
      cell.invalidate()

    # Since I'm invalid, I no longer depend on anything.
    Dataflow.removeAllDependencies(this)



Dataflow.addDependency = (dependent, dependency) ->
  dependent._dependencies.add(dependency)
  dependency._dependents.add(dependent)

Dataflow.removeDependency = (dependent, dependency) ->
  dependent._dependencies.delete(dependency)
  dependency._dependents.delete(dependent)

Dataflow.removeAllDependencies = (dependent) ->
  dependent._dependencies.forEach (dependency) ->
    Dataflow.removeDependency(dependent, dependency)



class Dataflow.Spread
  constructor: (@items, @parent) ->
  root: ->
    if @parent
      return @parent.root()
    else
      return this










