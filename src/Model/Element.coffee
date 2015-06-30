Node = require "./Node"
Link = require "./Link"

module.exports = Element = Node.createVariant
  constructor: ->
    # Call "super" constructor
    Node.constructor.apply(this, arguments)

    @expanded = false
    # TODO: Set up cells for matrix, graphic, etc.


