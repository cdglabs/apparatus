_ = require "underscore"


module.exports = class JspmCache
  constructor: ->
    @_modules = {}
    @_callbacksToRun = {}

  getSync: (moduleName) ->
    @_modules[moduleName]  # will be undefined if module is not saved

  get: (moduleName, callback) ->
    # Either the module is cached...
    if _.has(@_modules, moduleName)
      return @_modules[moduleName]

    # Or it is already being loaded...
    else if @_callbacksToRun[moduleName]
      return JspmCache.IS_LOADING

    # Or it's totally new...
    else
      @_callbacksToRun[moduleName] = callback

      System.import(moduleName).then(
        (result) =>
          @_modules[moduleName] = result
          callbackToRun = @_callbacksToRun[moduleName]
          delete @_callbacksToRun[moduleName]
          callbackToRun()
        (error) =>
          @_modules[moduleName] = error
          callbackToRun = @_callbacksToRun[moduleName]
          delete @_callbacksToRun[moduleName]
          callbackToRun()
      )

  @IS_LOADING: "__JspmCache::IS_LOADING__"
