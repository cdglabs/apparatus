_ = require "underscore"
Node = require "./Node"
Model = require "./Model"


# Helper methods for nodes which have attributes attached.
module.exports = NodeWithAttributes = Node.createVariant
  label: "Node With Attributes"

  attributes: ->
    @childrenOfType(Model.Attribute)

  getAttributesByName: ->
    _.indexBy @attributes(), "name"

  getAttributesValuesByName: ->
    _.mapObject @getAttributesByName(), (attr) -> attr.value()
