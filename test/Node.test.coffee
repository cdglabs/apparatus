test = require("tape")

Node = require("../src/Model/Node")


test "basic prototype works", (t) ->
  a = Node.createVariant({foo: 20})
  b = a.createVariant()
  t.equal(b.foo, 20)
  t.end()

test "chaining constructors works", (t) ->
  called = false
  a = Node.createVariant {
    constructor: ->
      called = true
      Node.constructor.apply(this, arguments)
  }
  t.ok(called)
  t.end()

test "adding/removing children changes parent", (t) ->
  a = Node.createVariant()
  b = Node.createVariant()
  c = Node.createVariant()

  a.addChild(b)
  a.addChild(c)

  t.equal(b.parent(), a)
  t.same(a.children(), [b, c])

  b.addChild(c)
  t.equal(c.parent(), b)
  t.same(a.children(), [b])
  t.same(b.children(), [c])

  t.end()

test "creating variants copies structure", (t) ->
  a = Node.createVariant()
  b = Node.createVariant()
  c = Node.createVariant()
  d = Node.createVariant()

  a.addChild(b)
  a.addChild(c)
  b.addChild(d)

  a2 = a.createVariant()

  t.equal(a2.children().length, 2)
  t.equal(a2.children()[0].children().length, 1)

  t.end()

test "changing structure changes variants", (t) ->
  a = Node.createVariant()
  a2 = a.createVariant()

  b = Node.createVariant()
  c = Node.createVariant()
  a.addChild(b)
  a.addChild(c)

  t.equal(a2.children().length, 2)

  a.removeChild(c)
  t.equal(a2.children().length, 1)

  t.end()

test "adding a variant as a child (to create recursion) does not crash / overflow", (t) ->
  a = Node.createVariant()
  a2 = a.createVariant()

  a.addChild(a2)
  t.same(a.children(), [a2])

  cursor = a2
  for i in [0 ... 6]
    t.equal(cursor.children().length, 1)
    cursor = cursor.children()[0]

  t.end()
