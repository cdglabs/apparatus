test = require("tape")

node = require("../src/Model/node")


test "basic prototype works", (t) ->
  a = node.createVariant()
  b = a.createVariant()
  a.foo = 20
  t.equal(b.foo, 20)
  t.end()

test "adding/removing children changes parent", (t) ->
  a = node.createVariant()
  b = node.createVariant()
  c = node.createVariant()

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
  a = node.createVariant()
  b = node.createVariant()
  c = node.createVariant()
  d = node.createVariant()

  a.addChild(b)
  a.addChild(c)
  b.addChild(d)

  a2 = a.createVariant()

  t.equal(a2.children().length, 2)
  t.equal(a2.children()[0].children().length, 1)

  t.end()

test "changing structure changes variants", (t) ->
  a = node.createVariant()
  a2 = a.createVariant()

  b = node.createVariant()
  c = node.createVariant()
  a.addChild(b)
  a.addChild(c)

  t.equal(a2.children().length, 2)

  a.removeChild(c)
  t.equal(a2.children().length, 1)

  t.end()

test "adding a variant as a child (to create recursion) does not crash / overflow", (t) ->
  a = node.createVariant()
  a2 = a.createVariant()

  a.addChild(a2)
  t.same(a.children(), [a2])

  cursor = a2
  for i in [0 ... 6]
    t.equal(cursor.children().length, 1)
    cursor = cursor.children()[0]

  t.end()
