_ = require "underscore"
Dataflow = require "../Dataflow/Dataflow"
Graphic = require "../Graphic/Graphic"
Util = require "../Util/Util"


module.exports = Model = {}

# These are *classes*
Model.Project = require "./Project"
Model.ParticularElement = require "./ParticularElement"
Model.Layout = require "./Layout"

# These are *variants of the Node object*
Model.Node = require "./Node"
Model.Link = require "./Link"
Model.Attribute = require "./Attribute"
Model.Element = require "./Element"


Model.Editor = require "./Editor"


Model.Variable = Model.Attribute.createVariant
  label: "Variable"

# Links an Element to the Attributes it controls.
Model.ControlledAttributeLink = Model.Link.createVariant
  label: "ControlledAttributeLink"

# Links an Attribute to the Attributes it references in its expression.
Model.ReferenceLink = Model.Link.createVariant
  label: "ReferenceLink"

createAttribute = (label, name, exprString) ->
  attribute = Model.Attribute.createVariant
    label: label
    name: name
  attribute.setExpression(exprString)
  return attribute

# =============================================================================
# Components
# =============================================================================

Model.Component = Model.Node.createVariant
  label: "Component"

  attributes: ->
    @childrenOfType(Model.Attribute)

  getAttributesByName: ->
    _.indexBy @attributes(), "name"

  getAttributesValuesByName: ->
    result = {}
    for attribute in @attributes()
      name = attribute.name
      value = attribute.value()
      result[name] = value
    return result

  graphicClass: Graphic.Component

  graphic: ->
    graphic = new @graphicClass()
    _.extend graphic, @getAttributesValuesByName()
    return graphic



Model.Transform = Model.Component.createVariant
  label: "Transform"

  matrix: ->
    {x, y, sx, sy, rotate} = @getAttributesValuesByName()
    return Util.Matrix.naturalConstruct(x, y, sx, sy, rotate)
  defaultAttributesToChange: ->
    {x, y} = @getAttributesByName()
    return [x, y]
  controllableAttributes: ->
    {x, y, sx, sy, rotate} = @getAttributesByName()
    return [x, y, sx, sy, rotate]
  controlPoints: ->
    {x, y, sx, sy} = @getAttributesByName()
    return [
      {point: [0, 0], attributesToChange: [x, y], filled: true}
      {point: [1, 0], attributesToChange: [sx], filled: false}
      {point: [0, 1], attributesToChange: [sy], filled: false}
    ]

Model.Transform.addChildren [
  createAttribute("X", "x", "0.00")
  createAttribute("Y", "y", "0.00")
  createAttribute("Scale X", "sx", "1.00")
  createAttribute("Scale Y", "sy", "1.00")
  createAttribute("Rotate", "rotate", "0.00")
]



Model.Fill = Model.Component.createVariant
  label: "Fill"
  graphicClass: Graphic.Fill

Model.Fill.addChildren [
  createAttribute("Fill Color", "color", "rgba(0.93, 0.93, 0.93, 1.00)")
]


Model.Stroke = Model.Component.createVariant
  label: "Stroke"
  graphicClass: Graphic.Stroke

Model.Stroke.addChildren [
  createAttribute("Stroke Color", "color", "rgba(0.60, 0.60, 0.60, 1.00)")
  createAttribute("Line Width", "lineWidth", "1")
]


# =============================================================================
# Elements
# =============================================================================

Model.Shape = Model.Element.createVariant
  label: "Shape"

Model.Shape.addChildren [
  Model.Transform.createVariant()
]


Model.Group = Model.Shape.createVariant
  label: "Group"
  graphicClass: Graphic.Group


Model.Anchor = Model.Shape.createVariant
  label: "Anchor"
  graphicClass: Graphic.Anchor

createAnchor = (x, y) ->
  anchor = Model.Anchor.createVariant()
  transform = anchor.childOfType(Model.Transform)
  attributes = transform.getAttributesByName()
  attributes.x.setExpression(x)
  attributes.y.setExpression(y)
  return anchor


Model.PathComponent = Model.Component.createVariant
  _devLabel: "PathComponent"
  label: "Path"
  graphicClass: Graphic.PathComponent

Model.PathComponent.addChildren [
  createAttribute("Close Path", "closed", "true")
]

Model.Path = Model.Shape.createVariant
  label: "Path"
  graphicClass: Graphic.Path

Model.Path.addChildren [
  Model.PathComponent.createVariant()
  Model.Fill.createVariant()
  Model.Stroke.createVariant()
]


Model.Circle = Model.Path.createVariant
  label: "Circle"
  graphicClass: Graphic.Circle


Model.Rectangle = Model.Path.createVariant
  label: "Rectangle"

Model.Rectangle.addChildren [
  createAnchor("0.00", "0.00")
  createAnchor("0.00", "1.00")
  createAnchor("1.00", "1.00")
  createAnchor("1.00", "0.00")
]


Model.TextComponent = Model.Component.createVariant
  _devLabel: "TextComponent"
  label: "Text"
  graphicClass: Graphic.TextComponent

Model.TextComponent.addChildren [
  createAttribute("Text", "text", '"Text"')
  createAttribute("Font", "fontFamily", '"Lucida Grande"')
  createAttribute("Color", "color", "rgba(0.20, 0.20, 0.20, 1.00)")
  createAttribute("Align", "textAlign", '"start"')
  createAttribute("Baseline", "textBaseline", '"alphabetic"')
]

Model.Text = Model.Shape.createVariant
  label: "Text"
  graphicClass: Graphic.Text

Model.Text.addChildren [
  Model.TextComponent.createVariant()
]
