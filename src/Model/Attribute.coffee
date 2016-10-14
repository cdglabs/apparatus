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
    # Get an up-to-date (possibly cached) parsing:
    parsing = @_parsing()

    if @__overrideValue  # The attribute has been externally overriden
      return @__overrideValue
    else if parsing.hasOwnProperty("value")  # The parsing determines a constant value
      return parsing.value
    else if parsing.hasOwnProperty("evaluate")  # The parsing determines a custom evaluate function
      try
        return parsing.evaluate()
      catch error
        return error
    else if parsing.hasOwnProperty("compiledExpression")  # The parsing determines a compiled expression
      if (circularReferencePath = @circularReferencePath())?
        return new CircularReferenceError(circularReferencePath)

      referenceValues = _.mapObject @references(), (referenceAttribute) ->
        referenceAttribute.value()

      try
        return parsing.compiledExpression.evaluate(referenceValues)
      catch error
        if error instanceof Dataflow.UnresolvedSpreadError
          throw error
        else
          return error

  _parsing: ->
    if not @hasOwnProperty("__parsing") or @__parsing.exprString != @exprString
      # We need to parse now

      @__parsing = {
        exprString: @exprString
      }

      if Util.isNumberString(@exprString)
        _.extend @__parsing, {
          type: "number"
          value: parseFloat(@exprString)
          precision: Util.precision(@exprString)
        }
      else if rangedNumberMatch = Util.matchRangedNumberString(@exprString)
        _.extend @__parsing, {
          type: "rangedNumber"
          value: parseFloat(rangedNumberMatch.valueStr)
          low: parseFloat(rangedNumberMatch.lowStr)
          high: parseFloat(rangedNumberMatch.highStr)
          precision: Util.precision(rangedNumberMatch.valueStr)
        }
      else if match = @exprString.replace(" ", "").match(/spreadLike\(([^,]*)(,(.*))?\)/)
        refId = match[1]
        defaultValue = if match[3] then +match[3] else 0
        precision = if match[3] then Util.precision(match[3]) else 2
        _.extend @__parsing, {
          type: "specialForm"
          specialForm: "spreadLike"
          precision: precision
          evaluate: () =>
            # TODO: Ideally, we would only rerun this when the ref changes its value, not every frame
            # (even if @_spreadLikeValue is changing!)
            ref = @references()[refId]
            refValue = ref?.value.asSpread()
            if not (refValue instanceof Spread)
              return new Error("'spreadLike' is a special form that needs a spread reference as input")
            # Now we want to update @_spreadLikeValue based on changes in refValue's size & dimensions.
            if not @hasOwnProperty('_spreadLikeValue')
              @_spreadLikeValue = defaultValue
            @_spreadLikeValue = Spread.reshapeLike(@_spreadLikeValue, refValue, defaultValue)
            return @_spreadLikeValue
        }
      else if match = @exprString.replace(" ", "").match(/unspread\(([^,]*)\)/)
        refId = match[1]
        _.extend @__parsing, {
          type: "specialForm"
          specialForm: "unspread"
          evaluate: () =>
            ref = @references()[refId]
            refValue = ref?.value.asSpread()
            if not (refValue instanceof Spread)
              return new Error("'unspread' is a special form that needs a spread reference as input")
            return refValue.toArray()
        }
      else if match = @exprString.replace(" ", "").match(/prev\(([^,]*)(,(.*))?\)/)
        refId = match[1]
        defaultValue = match[3] and +match[3]
        _.extend @__parsing, {
          type: "specialForm"
          specialForm: "prev"
          evaluate: () =>
            ref = @references()[refId]
            refValue = ref?.value.asSpread()
            if not (refValue instanceof Spread)
              return new Error("'prev' is a special form that needs a spread reference as input")
            refValueClone = refValue.cloneSingleLevel()
            popped = refValueClone.items.pop()
            refValueClone.items.unshift(defaultValue ? popped)
            return refValueClone
        }
      else if match = @exprString.replace(" ", "").match(/next\(([^,]*)(,(.*))?\)/)
        refId = match[1]
        defaultValue = match[3] and +match[3]
        _.extend @__parsing, {
          type: "specialForm"
          specialForm: "next"
          evaluate: () =>
            ref = @references()[refId]
            refValue = ref?.value.asSpread()
            if not (refValue instanceof Spread)
              return new Error("'next' is a special form that needs a spread reference as input")
            refValueClone = refValue.cloneSingleLevel()
            shifted = refValueClone.items.shift()
            refValueClone.items.push(defaultValue ? shifted)
            return refValueClone
        }
      else if match = @exprString.replace(" ", "").match(/spreadIndex\(([^,]*)\)/)
        refId = match[1]
        _.extend @__parsing, {
          type: "specialForm"
          specialForm: "next"
          evaluate: () =>
            ref = @references()[refId]
            refValue = ref?.value.asSpread()
            if not (refValue instanceof Spread)
              return new Error("'spreadIndex' is a special form that needs a spread reference as input")
            return refValue.mapSingleLevel((x, i) -> i)
        }
      else
        compiledExpression = new CompiledExpression(this)
        if compiledExpression.isSyntaxError
          compiledExpression.fn = @__compiledExpression?.fn ? -> new Error("Syntax error")
        _.extend @__parsing, {
          type: "expression"
          compiledExpression: compiledExpression
        }

      # HACK: Where does this belong?
      if @__parsing.specialForm != "spreadLike"
        delete @_spreadLikeValue

    return @__parsing

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

  deleteExpression: ->
    delete @exprString

    # Remove all existing reference links
    for referenceLink in @childrenOfType(Model.ReferenceLink)
      @removeChild(referenceLink)

  # This is only used for the 'hover' attribute (so far).
  setOverrideValue: (overrideValue) ->
    @__overrideValue = overrideValue
  deleteOverrideValue: () ->
    delete @__overrideValue
  hasOverrideValue: () ->
    @hasOwnProperty("__overrideValue")

  # This is used for dragging
  # HACK: `value` is a string, cuz it includes precision.
  setAt: (value, spreadEnv) ->
    if @hasOwnProperty("_spreadLikeValue")
      value = +value
      if @_spreadLikeValue instanceof Spread
        @_spreadLikeValue.setAt(value, spreadEnv)
      else
        @_spreadLikeValue = value
    else
      @setExpression(value)

  valueAt: (spreadEnv) ->
    value = @value()
    return spreadEnv.resolve(value)

  isDraggable: ->
    return @isNumber() or @hasOwnProperty("_spreadLikeValue")

  references: ->
    references = {}
    for referenceLink in @childrenOfType(Model.ReferenceLink)
      key = referenceLink.key
      attribute = referenceLink.target()
      references[key] = attribute
    return references

  hasReferences: -> _.any(@references(), -> true)

  isNumber: ->
    return @_parsing().type in ["number", "rangedNumber"]

  isString: ->
    return Util.isStringLiteral(@exprString)

  isKeyword: ->
    return Util.isKeywordLiteral(@exprString)

  isTrivial: ->
    return @isNumber() or @isString() or @isKeyword()

  isNovel: ->
    @hasOwnProperty("exprString")

  precision: ->
    return @_parsing().precision

  range: ->
    parsing = @_parsing()
    if parsing.type == 'rangedNumber'
      return {low: parsing.low, high: parsing.high}

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
    if not @_swatchColor
      @_swatchColor = editingElement.assignNewSwatchColor()
    return @_swatchColor




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
    labels = _.pluck(@attributePath, "label")
    @message = "Circular reference: #{labels.join(" -> ")}"
