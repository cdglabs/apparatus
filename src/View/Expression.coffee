_ = require "underscore"
R = require "./R"
Model = require "../Model/Model"
Dataflow = require "../Dataflow/Dataflow"
Util = require "../Util/Util"


R.create "Expression",
  propTypes:
    attribute: Model.Attribute

  render: ->
    attribute = @props.attribute

    R.div {className: "Expression"},
      if not attribute.hasOverrideValue()
        R.ExpressionCode {attribute}
      R.ExpressionValue {attribute}

R.create "ExpressionValue",
  propTypes:
    attribute: Model.Attribute
  render: ->
    attribute = @props.attribute
    if attribute.isTrivial() and not attribute.hasOverrideValue()
      R.span {}
    else
      value = attribute.value()
      R.div {className: R.cx {
          ExpressionValue: true,
          isSyntaxError: @props.attribute.isSyntaxError()
        }},
        R.Value {value: value}

R.create "Value",
  propTypes:
    value: "any"
  render: ->
    value = @props.value
    R.span {className: "Value"},
      if value instanceof Error
        "(" + value + ")"
      else if _.isFunction(value)
        "(Function)"
      else if value instanceof Dataflow.Spread
        R.SpreadValue {spread: value}
      else if _.isNumber(value)
        Util.toMaxPrecision(value, 3)
      else
        R.div {style: {opacity: 0.7, display: "inline-block"}},
          R.ObjectInspector {
            data: value,
            theme: R.ObjectInspector.chromeLightTransparent
          }

# TODO: The styling/formatting for this could be better. Also it should
# highlight the particular selected item when appropriate.
R.create "SpreadValue",
  propTypes:
    spread: "any"

  contextTypes:
    project: Model.Project

  render: ->
    {spread} = @props
    {project} = @context
    {editingElement} = project

    maxSpreadItems = 5
    swatchColor = spread.origin.swatchColor(editingElement)
    delimiterStyle = {color: swatchColor, opacity: 0.75}

    R.span {className: "SpreadValue"},
      R.span {style: delimiterStyle}, "["
      for index in [0...Math.min(spread.items.length, maxSpreadItems)]
        value = spread.items[index]
        [
          R.span {key: index, className: "SpreadValueItem"},
            R.Value {value: value}
          if index < spread.items.length - 1
            R.span {style: delimiterStyle}, ","
        ]
      if spread.items.length > maxSpreadItems
        "..."
      R.span {style: delimiterStyle}, "]"
