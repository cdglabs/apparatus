Node = require "./Node"
Link = require "./Link"

module.exports = Attribute = Node.createVariant
  constructor: ->
    # Call "super"
    Node.constructor.apply(this, arguments)

    # TODO: set up cell

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

    @_setDirty()

  _setDirty: ->
    # TODO

  references: ->
    references = {}
    for referenceLink in @childrenOfType(ReferenceLink)
      key = referenceLink.key
      attribute = referenceLink.target()
      references[key] = attribute
    return references



ReferenceLink = Link.createVariant()
