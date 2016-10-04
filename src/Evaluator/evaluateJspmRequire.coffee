_ = require "underscore"
JspmCache = require "../Util/JspmCache"


jspmCache = new JspmCache()

module.exports.jspmRequire = jspmRequire = (jspmModuleName) ->
  # This means, get the module, or if it's not available yet, set up a callback
  maybeModule = jspmCache.get(jspmModuleName, -> Apparatus.refresh())

  if maybeModule == JspmCache.IS_LOADING
    throw Error("Module #{jspmModuleName} is still loading")

  if _.isError(maybeModule)
    throw maybeModule

  return maybeModule


module.exports.npmRequire = npmRequire = (npmModuleName) ->
  jspmRequire("npm:" + npmModuleName)
