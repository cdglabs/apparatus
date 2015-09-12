_ = require "underscore"
Dataflow = require "../Dataflow/Dataflow"


module.exports = spread = (start, end, increment=1) ->
  if _.isArray(start)
    return new Dataflow.Spread(start)

  if increment == 0
    throw "Spread increment cannot be 0"
  if !_.isFinite(increment)
    throw "Spread increment must be finite"

  n = (end - start) / increment
  array = (start + increment * i for i in [0 ... n])
  return new Dataflow.Spread(array)
