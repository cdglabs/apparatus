_ = require "underscore"
Util = require "../Util/Util"
Dataflow = require "../Dataflow/Dataflow"
Spread = require "../Dataflow/Spread"
Evaluator = require "../Evaluator/Evaluator"
Node = require "./Node"
Link = require "./Link"
Model = require "./Model"


module.exports = Attribute = Node.createVariant
  label: "Attribute"

  constructor: ->
    # Call "super" constructor
    Node.constructor.apply(this, arguments)

    @value = Dataflow.cell(@_value.bind(this))

    # Because the _swatchColor property is not inherited, it is initialized
    # in the constructor for every Attribute.
    @_swatchColor = false

  _value: ->
    if asSpreadLike = @asSpreadLike()
      {ref} = asSpreadLike
      refValue = ref.value.asSpread()
      if not refValue
        return undefined
      # Now we want to update @_overrideValue based on changes in refValue's size & dimensions.
      if !@hasOverrideValue()
        @_overrideValue = 0
      @_overrideValue = Spread.reshapeLike(@_overrideValue, refValue)

    if asUnspread = @asUnspread()
      {ref} = asUnspread
      refValue = ref.value.asSpread()
      return refValue.toArray()

    if @hasOverrideValue()
      return @_overrideValue

    # Optimization
    if @isNumber()
      return parseFloat(@exprString)

    if @_isDirty()
      @_updateCompiledExpression()

    if (circularReferencePath = @circularReferencePath())?
      return new CircularReferenceError(circularReferencePath)

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

    # TODO: There might be a cleaner way of doing this kind of cleanup
    if not @asSpreadLike()
      @deleteOverrideValue()

  deleteExpression: ->
    delete @exprString

    # Remove all existing reference links
    for referenceLink in @childrenOfType(Model.ReferenceLink)
      @removeChild(referenceLink)

  asSpreadLike: ->
    # TODO: this should be some kinda fancy parser, right?
    pattern = /spreadLike\(([^,]*)(,(.*))?\)/
    if match = @exprString.replace(" ", "").match(pattern)
      refId = match[1]
      ref = @references()[refId]
      precision = match[3] and +match[3]
      return {ref, precision}
    else
      return false

  asUnspread: ->
    # TODO: this should be some kinda fancy parser, right?
    pattern = /unspread\(([^,]*)\)/
    if match = @exprString.replace(" ", "").match(pattern)
      refId = match[1]
      ref = @references()[refId]
      return {ref}
    else
      return false

  precision: ->
    if asSpreadLike = @asSpreadLike()
      return asSpreadLike.precision ? 2
    else
      Util.precision(@exprString)

  setOverrideValue: (overrideValue) ->
    @_overrideValue = overrideValue

  deleteOverrideValue: () ->
    delete @_overrideValue

  hasOverrideValue: () ->
    @hasOwnProperty('_overrideValue')

  # TODO: value is a string here, I guess?
  setAt: (value, spreadEnv) ->
    if @hasOverrideValue()
      if @_overrideValue instanceof Spread
        @_overrideValue.setAt(+value, spreadEnv)
      else
        @_overrideValue = +value
    else
      @setExpression(value)

  valueAt: (spreadEnv) ->
    return spreadEnv.resolve(@value())

  isDraggable: ->
    return @isNumber() or !!@exprString.match(/spreadLike\((.*)\)/i)

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

  isString: ->
    return Util.isStringLiteral(@exprString)

  isKeyword: ->
    return Util.isKeywordLiteral(@exprString)

  isTrivial: ->
    return @isNumber() or @isString() or @isKeyword()

  isNovel: ->
    @hasOwnProperty("exprString")

  # Descends through all recursively referenced attributes. An object is
  # returned with two properties:
  #   dependencies: array consisting of the set of all recursive dependencies
  #     (will be reasonable even if a circular reference exists)
  #   circularReferencePath: a chain of dependencies resulting in a circular
  #     reference, if one exists, or null
  _analyzeDependencies: ->
    dependencies = []

    attributePath = []
    circularReferencePath = null

    recurse = (attribute) ->
      attributePath.push(attribute)
      # Detect circular references, and don't get trapped
      if attributePath.indexOf(attribute) != attributePath.length - 1
        circularReferencePath ?= attributePath.slice()
      else
        for referenceAttribute in _.values(attribute.references())
          dependencies.push(referenceAttribute)
          recurse(referenceAttribute)
      attributePath.pop()

    recurse(this)

    dependencies = _.unique(dependencies)

    return {
      dependencies
      circularReferencePath
    }

  # Returns all referenced attributes recursively. In other words every
  # attribute which, if it changed, would affect me.
  dependencies: ->
    return @_analyzeDependencies().dependencies

  # If there is a circular reference in the attribute's dependency graph,
  # returns a chain of dependencies representing it. Otherwise returns null.
  circularReferencePath: ->
    return @_analyzeDependencies().circularReferencePath

  parentElement: ->
    result = @parent()
    until !result or result.isVariantOf(Model.Element)
      result = result.parent()
    return result

  # editingElement is needed so that we can keep track of the next swatch color
  # to assign
  swatchColor: (editingElement) ->
    if not this._swatchColor
      this._swatchColor = editingElement.assignNewSwatchColor()
    return this._swatchColor




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

    # We assume an expression with no references and no parentheses must be a
    # constant. (Parentheses mean there might be a non-referentially-transparent
    # function call.)
    if @referenceKeys.length == 0 and @exprString.indexOf("(") == -1
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

Attribute.CircularReferenceError = class CircularReferenceError extends Error
  constructor: (@attributePath) ->
    labels = _.pluck(@attributePath, 'label')
    @message = "Circular reference: #{labels.join(' -> ')}"
