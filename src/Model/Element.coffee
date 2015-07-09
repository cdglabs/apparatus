Node = require "./Node"
Link = require "./Link"
Model = require "./Model"


module.exports = Element = Node.createVariant
  constructor: ->
    # Call "super" constructor
    Node.constructor.apply(this, arguments)

    @expanded = false
    # TODO: Set up cells for matrix, graphic, etc.


  childElements: -> @childrenOfType(Element)

  variables: -> @childrenOfType(Model.Variable)

  components: -> @childrenOfType(Model.Component)
