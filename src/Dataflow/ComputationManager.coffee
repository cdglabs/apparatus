###

A ComputationManager is used to memoize functions within a computation. Use
ComputationManager.run(callback) to start a new computation and then any
memoized functions will be memoized within that computation.

TODO: Write tests

###

module.exports = class ComputationManager
  constructor: ->
    @isRunning = false
    @counter = 0

  # Any memoized functions (see below) that are called within callback will
  # never executed more than once. They will instead return their cached
  # value.
  run: (callback) ->
    if !@isRunning
      @isRunning = true
      @counter++
      try
        return callback()
      finally
        @isRunning = false
    else
      callback()

  # Takes a function and returns a memoized version.
  memoize: (fn) ->
    cachedValue = null
    lastEvaluated = -1
    return =>
      if lastEvaluated != @counter
        cachedValue = fn()
        lastEvaluated = @counter
      return cachedValue
