_ = require "underscore"
Util = require "../Util/Util"
Dataflow = require "../Dataflow/Dataflow"
Node = require "./Node"
Link = require "./Link"


ReferenceLink = Link.createVariant()

uninitializedCellFn = ->
  throw "Attribute not initialized"

module.exports = Attribute = Node.createVariant
  constructor: ->
    # Call "super"
    Node.constructor.apply(this, arguments)

    @__cell = new Dataflow.Cell(uninitializedCellFn)

  value: ->
    if @__cell.fn == uninitializedCellFn
      @_compile()
    @__cell.value()

  setExpression: (exprString, references={}) ->
    @exprString = ""+exprString

    # Remove all existing reference links
    for referenceLink in @childrenOfType(ReferenceLink)
      @removeChild(referenceLink)

    # Create appropriate reference links
    for own key, attribute of references
      referenceLink = ReferenceLink.createVariant()
      referenceLink.key = key
      referenceLink.setTarget(attribute)
      @addChild(referenceLink)

    @_compile()

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

  _compile: ->
    # TODO: Call compile on all my variants!

    if @isNumber()
      value = parseFloat(@exprString)
      @_setFn -> value
      return

    wrapped = @_wrapped()
    compiled = Util.jsEvaluate(wrapped)

    if !@hasReferences()
      value = compiled()
      @_setFn -> value
      return

    @_setFn =>
      referenceValues = _.mapObject @references(), (attribute) ->
        attribute.value()
      return compiled(referenceValues)

  _setFn: (fn) ->
    @__cell.fn = fn

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
