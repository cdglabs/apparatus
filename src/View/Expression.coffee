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
        "(Error)"
      else if _.isFunction(value)
        "(Function)"
      else if value instanceof Dataflow.Spread
        # TODO: Make this better
        "(Spread) " + JSON.stringify(value.items)
      else if _.isNumber(value)
        Util.toMaxPrecision(value, 3)
      else
        JSON.stringify(value)

R.create "SpreadValue",
  propTypes:
    spread: "any"
  maxSpreadItems: 5
  render: ->
    R.span {className: "SpreadValue"},
      for index in [0...Math.min(@spread.length, @maxSpreadItems)]
        value = @spread.take(index)
        R.span {className: "SpreadValueItem"},
          R.Value {value: value}
      if @spread.length > @maxSpreadItems
        "..."
