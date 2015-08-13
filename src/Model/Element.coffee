_ = require "underscore"
Node = require "./Node"
Link = require "./Link"
Model = require "./Model"
Dataflow = require "../Dataflow/Dataflow"
Util = require "../Util/Util"


ControlledAttributeLink = Link.createVariant()

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


  # ===========================================================================
  # Getters
  # ===========================================================================

  childElements: -> @childrenOfType(Element)

  variables: -> @childrenOfType(Model.Variable)

  components: -> @childrenOfType(Model.Component)

  attributes: ->
    result = []
    for variable in @variables()
      result.push(variable)
    for component in @components()
      for attribute in component.attributes()
        result.push(attribute)
    return result

  collectAllAttributes: ->
    result = @attributes()
    for childElement in @childElements()
      result.push(childElement.collectAllAttributes()...)
    return result


  # ===========================================================================
  # Actions
  # ===========================================================================

  addVariable: ->
    variable = Model.Variable.createVariant()
    variable.setExpression("0.00")
    @addChild(variable)
    return variable


  # ===========================================================================
  # Controlled Attributes
  # ===========================================================================

  controlledAttributes: ->
    controlledAttributes = []
    for controlledAttributeLink in @childrenOfType(ControlledAttributeLink)
      attribute = controlledAttributeLink.target()
      controlledAttributes.push(attribute)
    return controlledAttributes

  addControlledAttribute: (attributeToAdd) ->
    controlledAttributeLink = ControlledAttributeLink.createVariant()
    controlledAttributeLink.setTarget(attributeToAdd)
    @addChild(controlledAttributeLink)

  removeControlledAttribute: (attributeToRemove) ->
    for controlledAttributeLink in @childrenOfType(ControlledAttributeLink)
      attribute = controlledAttributeLink.target()
      if attribute == attributeToRemove
        @removeChild(controlledAttributeLink)

  # An implicitly controlled attribute is a controlled attribute or a
  # dependency of a controlled attribute.
  implicitlyControlledAttributes: ->
    result = []
    controlledAttributes = @controlledAttributes()
    for attribute in controlledAttributes
      result.push(attribute)
      result.push(attribute.dependencies()...)
    result = _.unique(result)
    return result

  # ===========================================================================
  # Attributes to change
  # ===========================================================================

  attributesToChange: ->
    attributesToChange = @implicitlyControlledAttributes()
    if attributesToChange.length == 0
      attributesToChange = @defaultAttributesToChange()

    # We can only change numbers.
    attributesToChange = _.filter attributesToChange, (attribute) ->
      attribute.isNumber()

    return attributesToChange

  defaultAttributesToChange: ->
    result = []
    for component in @components()
      continue unless component.defaultAttributesToChange?
      result.push(component.defaultAttributesToChange()...)
    return result


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

    spreadEnv = Dataflow.currentSpreadEnv()
    graphic.particularElement = new Model.ParticularElement(this, spreadEnv)

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
