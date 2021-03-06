_ = require "underscore"
d3chromatic = require "d3-scale-chromatic"
NodeWithAttributes = require "./NodeWithAttributes"
Link = require "./Link"
Model = require "./Model"
Dataflow = require "../Dataflow/Dataflow"
Util = require "../Util/Util"


module.exports = Element = NodeWithAttributes.createVariant
  label: "Element"

  constructor: ->
    # Call "super" constructor
    NodeWithAttributes.constructor.apply(this, arguments)

    # Because the expanded properly is not inherited, it is initialized in
    # the constructor for every Element.
    @expanded = false

    # This one too
    @_nextSwatchColorCode = 0

    # These methods need to be cells because we want to be able to call their
    # asSpread version. Note that we need to keep the original method around
    # (as the _version) so that inheritance doesn't try to make a cell out of
    # a cell.
    propsToCellify = [
      "graphic"
      "contextMatrix"
      "accumulatedMatrix"
      "contextFilter"
      "accumulatedFilter"
    ]
    for prop in propsToCellify
      this[prop] = Dataflow.cell(this["_" + prop].bind(this))

  # viewMatrix determines the pan and zoom of an Element. It is only used for
  # Elements that can be a Project.editingElement (i.e. Elements within the
  # create panel). The default is zoomed to 100 pixels per unit.
  viewMatrix: new Util.Matrix(100, 0, 0, 100, 0, 0)

  # Sets the viewMatrix so that the view (of size viewWidth x viewHeight)
  # contains the entire region of interest, centered, as large as possible.
  # roi is in the format {x: [lo, hi], y: [lo, hi]}.
  zoomViewMatrixToRegionOfInterest: (roi, viewWidth, viewHeight) ->
    scaleFactor = Math.min(
      viewWidth / (roi.x[1] - roi.x[0]),
      viewHeight / (roi.y[1] - roi.y[0]))
    @viewMatrix =
      new Util.Matrix()
      .scale(scaleFactor, scaleFactor)
      .translate(
        -(roi.x[1] + roi.x[0]) / 2,
        -(roi.y[1] + roi.y[0]) / 2)


  # ===========================================================================
  # Getters
  # ===========================================================================

  childElements: -> @childrenOfType(Element)

  variables: -> @childrenOfType(Model.Variable)

  components: -> @childrenOfType(Model.Component)

  # Includes attributes of components!
  allAttributes: ->
    result = []
    for variable in @variables()
      result.push(variable)
    for component in @components()
      for attribute in component.attributes()
        result.push(attribute)
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
    for controlledAttributeLink in @childrenOfType(Model.ControlledAttributeLink)
      attribute = controlledAttributeLink.target()
      controlledAttributes.push(attribute)
    return controlledAttributes

  addControlledAttribute: (attributeToAdd) ->
    controlledAttributeLink = Model.ControlledAttributeLink.createVariant()
    controlledAttributeLink.setTarget(attributeToAdd)
    @addChild(controlledAttributeLink)

  removeControlledAttribute: (attributeToRemove) ->
    for controlledAttributeLink in @childrenOfType(Model.ControlledAttributeLink)
      attribute = controlledAttributeLink.target()
      if attribute == attributeToRemove
        @removeChild(controlledAttributeLink)

  isController: ->
    return @controlledAttributes().length > 0

  # An implicitly controlled attribute is a controlled attribute or a
  # dependency of a controlled attribute.
  implicitlyControlledAttributes: ->
    return @allDependencies(@controlledAttributes())

  # A controllable attribute is one which, if changed, would affect my
  # geometry. Thus all attributes within Transform components, their
  # dependencies, as well as all controllable attributes up my parent chain.
  controllableAttributes: ->
    _.unique(@_controllableAttributes())
  _controllableAttributes: ->
    result = []
    for component in @components()
      continue unless component.controllableAttributes?
      for attribute in component.controllableAttributes()
        result.push(attribute)
        result.push(attribute.dependencies()...)
    if @parent()
      result.push(@parent()._controllableAttributes()...)
    return result


  # ===========================================================================
  # Attributes to change
  # ===========================================================================

  attributesToChange: ->
    attributesToChange = @implicitlyControlledAttributes()
    if attributesToChange.length == 0
      attributesToChange = @defaultAttributesToChange()
    attributesToChange = @onlyDraggable(attributesToChange)
    return attributesToChange

  defaultAttributesToChange: ->
    result = []
    for component in @components()
      continue unless component.defaultAttributesToChange?
      result.push(component.defaultAttributesToChange()...)
    return result


  # ===========================================================================
  # Control Points
  # ===========================================================================

  controlPoints: ->
    result = []
    for component in @components()
      continue unless component.controlPoints?
      controlPoints = component.controlPoints()
      for controlPoint in controlPoints
        attributesToChange = controlPoint.attributesToChange
        attributesToChange = @allDependencies(attributesToChange)
        attributesToChange = @onlyDraggable(attributesToChange)
        controlPoint.attributesToChange = attributesToChange
      result.push(controlPoints...)
    return result


  # ===========================================================================
  # Attribute List Helpers
  # ===========================================================================

  allDependencies: (attributes) ->
    result = []
    for attribute in attributes
      result.push(attribute)
      result.push(attribute.dependencies()...)
    return _.unique(result)

  onlyDraggable: (attributes) ->
    _.filter attributes, (attribute) ->
      attribute.isDraggable()


  # ===========================================================================
  # Geometry
  # ===========================================================================

  matrix: ->
    matrix = new Util.Matrix()
    for transform in @childrenOfType(Model.Transform)
      matrix = matrix.compose(transform.matrix())
    return matrix

  _contextMatrix: ->
    parent = @parent()
    if parent and parent.isVariantOf(Element)
      return parent.accumulatedMatrix()
    else
      return new Util.Matrix()

  _accumulatedMatrix: ->
    return @contextMatrix().compose(@matrix())


  # ===========================================================================
  # Filter
  # ===========================================================================

  filter: ->
    generalComponent = @childOfType(Model.GeneralComponent)
    if generalComponent
      return generalComponent.filter()
    else
      # Backwards compatibility
      return ""

  _contextFilter: ->
    parent = @parent()
    if parent and parent.isVariantOf(Element)
      return parent.accumulatedFilter()
    else
      return ""

  _accumulatedFilter: ->
    # Apply filters bottom-up
    return @filter() + @contextFilter()

  assignNewSwatchColor: ->
    toReturn = d3chromatic.schemeDark2[this._nextSwatchColorCode]
    this._nextSwatchColorCode = (this._nextSwatchColorCode + 1) % 8
    return toReturn



  # ===========================================================================
  # Graphic
  # ===========================================================================

  shouldShow: ->
    generalComponent = @childOfType(Model.GeneralComponent)
    if generalComponent
      return generalComponent.show()
    else
      # Backwards compatibility
      return true

  _graphic: ->
    graphic = new @graphicClass()

    spreadEnv = Dataflow.currentSpreadEnv()
    graphic.particularElement = new Model.ParticularElement(this, spreadEnv)

    graphic.matrix = @accumulatedMatrix()

    graphic.filter = @accumulatedFilter()

    graphic.components = _.map @components(), (component) ->
      component.graphic()

    graphic.childGraphics = _.flatten(_.map(@childElements(), (element) ->
      element.allGraphics()
    ))

    return graphic

  allGraphics: ->
    return [] if not @shouldShow()
    return [] if @_isBeyondMaxDepth()
    result = @graphic.asSpread()
    if result instanceof Dataflow.Spread
      return result.flattenToArray()
    else
      return [result]

  _isBeyondMaxDepth: ->
    # This might want to be adjustable somewhere rather than hard coded here.
    return @depth() > 20
