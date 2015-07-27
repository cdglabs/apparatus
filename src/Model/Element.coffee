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

    @_setupCells()

  childElements: -> @childrenOfType(Element)

  variables: -> @childrenOfType(Model.Variable)

  components: -> @childrenOfType(Model.Component)


  # ===========================================================================
  # Cells
  # ===========================================================================

  _setupCells: ->
    @__matrix = new Dataflow.Cell =>
      matrix = new Util.Matrix()
      for transform in @childrenOfType(Model.Transform)
        matrix = matrix.compose(transform.matrix())
      return matrix

    @__contextMatrix = new Dataflow.Cell =>
      parent = @parent()
      if parent and parent.isVariantOf(Element)
        return parent.accumulatedMatrix()
      else
        return new Util.Matrix()

    @__accumulatedMatrix = new Dataflow.Cell =>
      return @contextMatrix().compose(@matrix())

    # TODO: Set up cells for graphic, renderTree

  matrix: -> @__matrix.value()
  contextMatrix: -> @__contextMatrix.value()
  accumulatedMatrix: -> @__accumulatedMatrix.value()

