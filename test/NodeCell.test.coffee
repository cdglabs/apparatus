###

These test that working with a Node's children and parents invalidates
Dataflow Cells properly.

###

test = require "tape"

Dataflow = require "../src/Dataflow/Dataflow"
Node = require "../src/Model/Node"

test "Changing children invalidates cells", (t) ->
  a = Node.createVariant()
  b = Node.createVariant()
  a.addChild(b)

  cell = new Dataflow.Cell -> a.children().length

  t.equal(cell.value(), 1)

  a.removeChild(b)

  # Notice we should not need to invalidate cell. It should be invalidated by
  # the mutation to a's children.
  t.equal(cell.value(), 0)
  t.end()

test "Changing parent invalidates cells", (t) ->
  a = Node.createVariant()
  b = Node.createVariant()
  a.addChild(b)

  cell = new Dataflow.Cell -> b.parent()

  t.equal(cell.value(), a)

  a.removeChild(b)

  t.equal(cell.value(), null)
  t.end()
