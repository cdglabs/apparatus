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

    # TODO: Should more methods be cell'ed? Should these all be _private?
    @graphic = Dataflow.cell(@_graphic.bind(this))
    @accumulatedMatrix = Dataflow.cell(@_accumulatedMatrix.bind(this))


  childElements: -> @childrenOfType(Element)

  variables: -> @childrenOfType(Model.Variable)

  components: -> @childrenOfType(Model.Component)


  # ===========================================================================
  # Geometry
  # ===========================================================================

  matrix: ->
    matrix = new Util.Matrix()
    for transform in @childrenOfType(Model.Transform)
      matrix = matrix.compose(transform.matrix())
    return matrix

  contextMatrix: ->
    parent = @parent()
    if parent and parent.isVariantOf(Element)
      return parent.accumulatedMatrix()
    else
      return new Util.Matrix()

  _accumulatedMatrix: ->
    return @contextMatrix().compose(@matrix())


  # ===========================================================================
  # Graphic
  # ===========================================================================

  _graphic: ->
    graphic = new @graphicClass()

    # These annotations are used to associate the graphic with the element and
    # spread environment it came from. Maybe they should be replaced by
    # ParticularElement.
    graphic.element = this
    graphic.spreadEnv = Dataflow.currentSpreadEnv()

    graphic.matrix = @accumulatedMatrix()

    graphic.components = _.map @components(), (component) ->
      component.graphic()

    graphic.childGraphics = _.flatten(_.map(@childElements(), (element) ->
      element.allGraphics()
    ))

    return graphic

  allGraphics: ->
    result = @graphic.asSpread()
    if result instanceof Dataflow.Spread
      return result.flattenToArray()
    else
      return [result]
