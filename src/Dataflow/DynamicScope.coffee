_ = require "underscore"

module.exports = class DynamicScope
  constructor: (@context={}) ->

  with: (newContext, fn) ->
    previousContext = @context
    @context = _.defaults(newContext, previousContext)
    try
      result = fn()
    finally
      @context = previousContext
    return result
