test = require("tape")

Dataflow = require("../src/Dataflow/Dataflow")


test "Values are computed correctly", (t) ->
  a = Dataflow.cell -> 4
  b = Dataflow.cell -> a() * 2
  t.equal(b(), 8)
  t.end()

test "Cacheing works", (t) ->
  aCount = 0
  bCount = 0
  cCount = 0
  a = Dataflow.cell ->
    aCount++
    return 4
  b = Dataflow.cell ->
    bCount++
    return a() * 2
  c = Dataflow.cell ->
    cCount++
    return b() + a()
  Dataflow.run ->
    t.equal(a(), 4)
    t.equal(b(), 8)
    t.equal(c(), 12)
    t.equal(aCount, 1)
    t.equal(bCount, 1)
    t.equal(cCount, 1)
  t.end()

test "Spreads work", (t) ->
  a = Dataflow.cell -> new Dataflow.Spread([0 ... 10], a)
  b = Dataflow.cell -> a() * 2
  c = Dataflow.cell -> a() + b()
  t.deepEqual(a().items, [0 ... 10])
  t.deepEqual(b().items, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18])
  t.deepEqual(c().items, [0, 3, 6, 9, 12, 15, 18, 21, 24, 27])
  t.end()

test "Spreads cross product", (t) ->
  a = Dataflow.cell -> new Dataflow.Spread([0 ... 8], a)
  b = Dataflow.cell -> new Dataflow.Spread([10, 20], b)
  c = Dataflow.cell -> a() * b()
  for item, index in c().items
    t.deepEqual(item.items, [index * 10, index * 20])
  t.end()

test "Spreads rejoin", (t) ->
  a = Dataflow.cell -> new Dataflow.Spread([0 ... 10], a)
  b = Dataflow.cell -> a() * 2
  c = Dataflow.cell -> a() * 3
  d = Dataflow.cell -> c() + b()
  t.deepEqual(a().items, [0 ... 10])
  t.deepEqual(b().items, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18])
  t.deepEqual(c().items, [0, 3, 6, 9, 12, 15, 18, 21, 24, 27])
  t.deepEqual(d().items, [0, 5, 10, 15, 20, 25, 30, 35, 40, 45])

  t.end()

test "All spreads should try to resolve as deep as possible", (t) ->
  a = Dataflow.cell -> new Dataflow.Spread([0, 1], a)
  b = Dataflow.cell -> a() * 2
  c = Dataflow.cell -> {a: a(), b: b.asSpread()}
  t.deepEqual(c().items, [{a: 0, b: 0}, {a: 1, b: 2}])
  d = Dataflow.cell -> {b: b.asSpread()}
  t.deepEqual(d().b.items, [0, 2])
  t.end()
