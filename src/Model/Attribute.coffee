_ = require "underscore"
Util = require "../Util/Util"
Dataflow = require "../Dataflow/Dataflow"
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

    switch parsing.type
      when "override", "number"
        # These types have constant values stored in the parsing...

        return parsing.value

      when "expression"
        # This type requires computation...

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

      if @hasOwnProperty("__overrideValue")
        _.extend @__parsing, {
          type: "override"
          value: @__overrideValue
        }
      else if Util.isNumberString(@exprString)
        _.extend @__parsing, {
          type: "number"
          value: parseFloat(@exprString)
        }
      else
        compiledExpression = new CompiledExpression(this)
        if compiledExpression.isSyntaxError
          compiledExpression.fn = @__compiledExpression?.fn ? -> new Error("Syntax error")
        _.extend @__parsing, {
          type: "expression"
          compiledExpression: compiledExpression
        }

    return @__parsing

  _clearParsing: ->
    delete @__parsing

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

  setOverrideValue: (overrideValue) ->
    @__overrideValue = overrideValue
    @_clearParsing()

  hasOverrideValue: () ->
    @_parsing().type == "override"

  references: ->
    references = {}
    for referenceLink in @childrenOfType(Model.ReferenceLink)
      key = referenceLink.key
      attribute = referenceLink.target()
      references[key] = attribute
    return references

  hasReferences: -> _.any(@references(), -> true)

  isNumber: ->
    return @_parsing().type == "number"

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
