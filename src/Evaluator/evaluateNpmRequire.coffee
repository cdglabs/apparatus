_ = require "underscore"
JspmCache = require "../Util/JspmCache"


jspmCache = new JspmCache()

module.exports = npmRequire = (moduleName) ->
  # This means, get the module, or if it's not available yet, set up a callback
  maybeModule = jspmCache.get("npm:" + moduleName, -> Apparatus.refresh())

  if maybeModule == JspmCache.IS_LOADING
    throw Error("Module #{moduleName} is still loading")

  if _.isError(maybeModule)
    throw maybeModule

  return maybeModule
