Node = require "./Node"
Link = require "./Link"
Model = require "./Model"
Dataflow = require "../Dataflow/Dataflow"
Util = require "../Util/Util"


module.exports = Element = Node.createVariant
  constructor: ->
    # Call "super" constructor
    Node.constructor.apply(this, arguments)

    # Because the expanded properly is not inherited, it is initialized in
    # this constructor for every Element.
    @expanded = false

    @__matrix = new Dataflow.Cell =>
      matrix = new Util.Matrix()
      for transform in @childrenOfType(Model.Transform)
        matrix = matrix.compose(transform.matrix())

    # TODO: Set up cells for accumulated matrix, graphic, renderTree


  childElements: -> @childrenOfType(Element)

  variables: -> @childrenOfType(Model.Variable)

  components: -> @childrenOfType(Model.Component)
