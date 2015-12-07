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
      R.ExpressionCode {attribute}
      R.ExpressionValue {attribute}

R.create "ExpressionValue",
  propTypes:
    attribute: Model.Attribute
  render: ->
    attribute = @props.attribute
    if attribute.isTrivial()
      R.span {}
    else
      value = attribute.value()
      R.div {className: "ExpressionValue"},
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
        JSON.stringify(value)

# TODO: The styling/formatting for this could be better. Also it should
# highlight the particular selected item when appropriate.
R.create "SpreadValue",
  propTypes:
    spread: "any"
  render: ->
    {spread} = @props
    maxSpreadItems = 5

    R.span {className: "SpreadValue"},
      for index in [0...Math.min(spread.items.length, maxSpreadItems)]
        value = spread.items[index]
        R.span {key: index, className: "SpreadValueItem"},
          R.Value {value: value}
      if spread.items.length > maxSpreadItems
        "..."
