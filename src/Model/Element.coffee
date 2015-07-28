_ = require "underscore"
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

    @__graphic = new Dataflow.Cell =>
      graphic = new @graphicClass()

      # TODO: In order for hit detection to work, Graphics will need to be
      # annotated with the Element they came from and the Spread context, in
      # other words with a ParticularElement.

      graphic.matrix = @accumulatedMatrix()

      graphic.components = _.map @components(), (component) ->
        component.graphic()

      graphic.childGraphics = _.flatten(_.map(@childElements(), (element) ->
        element.allGraphics()
      ))

      return graphic

  matrix: -> @__matrix.value()
  contextMatrix: -> @__contextMatrix.value()
  accumulatedMatrix: -> @__accumulatedMatrix.value()
  graphic: -> @__graphic.value()

  allGraphics: ->
    result = @__graphic.value(true)
    if result instanceof Dataflow.Spread
      return result.items
    else
      return [result]
