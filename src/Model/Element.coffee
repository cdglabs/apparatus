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
      console.log "called!", Dataflow.Evaluator.currentContext
      matrix = new Util.Matrix()
      for transform in @childrenOfType(Model.Transform)
        matrix = matrix.compose(transform.matrix())
      return matrix

    @__contextMatrix = new Dataflow.Cell =>
      parent = @parent()
      if parent and parent.isVariantOf(Element)
        return parent.__accumulatedMatrix.value()
      else
        return new Util.Matrix()

    dummyCell = new Dataflow.Cell -> 6

    @__accumulatedMatrix = new Dataflow.Cell =>
      console.log "__accumulatedMatrix called", Dataflow.Evaluator.currentContext
      dummyCell.value()
      console.log "at this point", @__accumulatedMatrix._dependencies.size
      v = @__matrix.value()
      console.log "and then", @__accumulatedMatrix._dependencies.size, Dataflow.Evaluator.currentContext
      # return v
      # return @__contextMatrix.value().compose(@__matrix.value())

    # TODO: Set up cells for graphic, renderTree


  childElements: -> @childrenOfType(Element)

  variables: -> @childrenOfType(Model.Variable)

  components: -> @childrenOfType(Model.Component)
