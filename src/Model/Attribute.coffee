_ = require "underscore"
Util = require "../Util/Util"
Dataflow = require "../Dataflow/Dataflow"
Evaluator = require "../Evaluator/Evaluator"
Node = require "./Node"
Link = require "./Link"
Model = require "./Model"


module.exports = Attribute = Node.createVariant
  constructor: ->
    # Call "super" constructor
    Node.constructor.apply(this, arguments)

    @value = Dataflow.cell(@_value.bind(this))

  _value: ->
    # Optimization
    if @isNumber()
      return parseFloat(@exprString)

    if @_isDirty()
      @_updateCompiledExpression()

    referenceValues = _.mapObject @references(), (referenceAttribute) ->
      referenceAttribute.value()

    try
      return @__compiledExpression.evaluate(referenceValues)
    catch error
      if error instanceof Dataflow.UnresolvedSpreadError
        throw error
      else
        return error

  _isDirty: ->
    return true if !@hasOwnProperty("__compiledExpression")
    return true if @__compiledExpression.exprString != @exprString
    return false

  _updateCompiledExpression: ->
    compiledExpression = new CompiledExpression(this)
    if compiledExpression.isSyntaxError
      compiledExpression.fn = @__compiledExpression?.fn ? -> new Error("Syntax error")
    @__compiledExpression = compiledExpression

  setExpression: (exprString, references={}) ->
    @exprString = String(exprString)

    # Remove all existing reference links
    for referenceLink in @childrenOfType(Model.ReferenceLink)
      @removeChild(referenceLink)

    # Create appropriate reference links
    for own key, attribute of references
      referenceLink = Model.ReferenceLink.createVariant()
      referenceLink.key = key
      referenceLink.setTarget(attribute)
      @addChild(referenceLink)

  references: ->
    references = {}
    for referenceLink in @childrenOfType(Model.ReferenceLink)
      key = referenceLink.key
      attribute = referenceLink.target()
      references[key] = attribute
    return references

  hasReferences: -> _.any(@references(), -> true)

  isNumber: ->
    return Util.isNumberString(@exprString)

  isTrivial: ->
    # TODO
    return @isNumber()

  isNovel: ->
    @hasOwnProperty("exprString")

  # Returns all referenced attributes recursively. In other words every
  # attribute which, if it changed, would affect me.
  dependencies: ->
    dependencies = []
    recurse = (attribute) ->
      for referenceAttribute in _.values(attribute.references())
        dependencies.push(referenceAttribute)
        recurse(referenceAttribute)
    recurse(this)
    dependencies = _.unique(dependencies)
    return dependencies

  parentElement: ->
    result = @parent()
    until result.isVariantOf(Model.Element)
      result = result.parent()
    return result




class CompiledExpression
  constructor: (@attribute) ->
    @exprString = @attribute.exprString
    @referenceKeys = _.keys(@attribute.references())

    if @exprString == ""
      @_setSyntaxError()
      return

    if Util.isNumberString(@exprString)
      value = parseFloat(@exprString)
      @_setConstant(value)
      return

    wrapped = @_wrapped()
    try
      compiled = Evaluator.evaluate(wrapped)
    catch error
      @_setSyntaxError()
      return

    compiled = @_wrapFunctionInSpreadCheck(compiled)

    if @referenceKeys.length == 0
      try
        value = compiled()
      catch error
        @_setConstant(error)
        return
      @_setConstant(value)
      return

    @_setFn(compiled)

  _setSyntaxError: ->
    @isSyntaxError = true

  _setConstant: (value) ->
    @isConstant = true
    @fn = -> value

  _setFn: (fn) ->
    @fn = fn

  evaluate: (referenceValues) ->
    return @fn(referenceValues)

  _wrapped: ->
    result    = "'use strict';\n"
    result   += "(function ($$$referenceValues) {\n"

    for referenceKey in @referenceKeys
      result += "  var #{referenceKey} = $$$referenceValues.#{referenceKey};\n"

    if @exprString.indexOf("return") == -1
      result += "  return #{@exprString};\n"
    else
      result += "\n\n#{@exprString}\n\n"

    result   += "});"
    return result

  _wrapFunctionInSpreadCheck: (fn) ->
    return =>
      result = fn(arguments...)
      if result instanceof Dataflow.Spread
        result.origin = @attribute
      return result


