test = require("tape")

DynamicScope = require("../src/Dataflow/DynamicScope")

test "Dynamic Scope works", (t) ->
  ds = new DynamicScope({a: 1})
  t.equal(ds.context.a, 1)
  ds.with {a: 2}, ->
    t.equal(ds.context.a, 2)
    ds.with {b: 4}, ->
      t.equal(ds.context.a, 2)
      t.equal(ds.context.b, 4)
    ds.with {a: 3}, ->
      t.equal(ds.context.a, 3)
    t.equal(ds.context.a, 2)
  t.equal(ds.context.a, 1)
  t.end()

test "Throwing an exception still clears scope properly", (t) ->
  ds = new DynamicScope({a: 1})
  t.equal(ds.context.a, 1)
  try
    ds.with {a: 2}, ->
      t.equal(ds.context.a, 2)
      throw "exception"
  t.equal(ds.context.a, 1)
  t.end()
