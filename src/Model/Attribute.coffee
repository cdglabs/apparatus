_ = require "underscore"
Util = require "../Util/Util"
Dataflow = require "../Dataflow/Dataflow"
Node = require "./Node"
Link = require "./Link"


ReferenceLink = Link.createVariant()

module.exports = Attribute = Node.createVariant
  constructor: ->
    # Call "super"
    Node.constructor.apply(this, arguments)

    @__isDirty = true

  value: ->
    if @__isDirty
      @_compile()
    try
      return @_fn()
    catch error
      if error instanceof Dataflow.UnresolvedSpreadError
        throw error
      else
        return error

  _setDirty: ->
    @__isDirty = true
    for variant in @variants()
      variant._setDirty()

  setExpression: (exprString, references={}) ->
    @exprString = String(exprString)

    # Remove all existing reference links
    for referenceLink in @childrenOfType(ReferenceLink)
      @removeChild(referenceLink)

    # Create appropriate reference links
    for own key, attribute of references
      referenceLink = ReferenceLink.createVariant()
      referenceLink.key = key
      referenceLink.setTarget(attribute)
      @addChild(referenceLink)

    @_setDirty()

  references: ->
    references = {}
    for referenceLink in @childrenOfType(ReferenceLink)
      key = referenceLink.key
      attribute = referenceLink.target()
      references[key] = attribute
    return references

  hasReferences: -> _.any(@references(), -> true)

  isNumber: ->
    return /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/.test(@exprString)

  isTrivial: ->
    # TODO
    return @isNumber()

  # ===========================================================================
  # Compiling
  # ===========================================================================

  _compile: ->
    if @exprString == ""
      @_setError()
      return

    if @isNumber()
      value = parseFloat(@exprString)
      @_setFn -> value
      return

    wrapped = @_wrapped()
    try
      compiled = Util.jsEvaluate(wrapped)
    catch error
      @_setError()
      return

    compiled = @_wrapFunctionInSpreadCheck(compiled)

    if !@hasReferences()
      try
        value = compiled()
      catch
        @_setError()
        return
      @_setFn -> value

    @_setFn =>
      referenceValues = _.mapObject @references(), (attribute) ->
        attribute.value()
      return compiled(referenceValues)

  _setFn: (fn) ->
    @_isSyntaxError = false
    @_fn = Dataflow.cell(fn)
    @__isDirty = false

  _setError: ->
    @_isSyntaxError = true
    @__isDirty = false

  _wrapped: ->
    result    = "'use strict';\n"
    result   += "(function ($$$referenceValues) {\n"

    for referenceKey, referenceAttribute of @references()
      result += "  var #{referenceKey} = $$$referenceValues.#{referenceKey};\n"

    if @exprString.indexOf("return") == -1
      result += "  return #{@exprString};\n"
    else
      result += "\n\n#{exprString}\n\n"

    result   += "});"
    return result

  _wrapFunctionInSpreadCheck: (fn) ->
    return =>
      result = fn(arguments)
      if result instanceof Dataflow.Spread
        result.origin = this
      return result
