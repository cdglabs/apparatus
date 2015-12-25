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

test "lineages basically work", (t) ->
  b = Node.createVariant()
  c = Node.createVariant()
  b.addChild(c)

  a2 = Node.createVariant()
  b2 = b.createVariant()
  a2.addChild(b2)
  c2 = c.findVariantWithHead(b2)

  b3 = b2.createVariant()
  c3 = c2.findVariantWithHead(b3)

  t.deepEqual(b.masterLineage(), [b, Node])
  t.deepEqual(c.masterLineage(), [c, Node])
  t.deepEqual(a2.masterLineage(), [a2, Node])
  t.deepEqual(b2.masterLineage(), [b2, b, Node])
  t.deepEqual(c2.masterLineage(), [c2, c, Node])
  t.deepEqual(b3.masterLineage(), [b3, b2, b, Node])
  t.deepEqual(c3.masterLineage(), [c3, c2, c, Node])

  t.deepEqual(b.parentThenMasterLineage(),
    [[b, "master"], [Node, "end"]])
  t.deepEqual(c.parentThenMasterLineage(),
    [[c, "parent"], [b, "master"], [Node, "end"]])
  t.deepEqual(a2.parentThenMasterLineage(),
    [[a2, "master"], [Node, "end"]])
  t.deepEqual(b2.parentThenMasterLineage(),
    [[b2, "parent"], [a2, "master"], [Node, "end"]])
  t.deepEqual(c2.parentThenMasterLineage(),
    [[c2, "parent"], [b2, "parent"], [a2, "master"], [Node, "end"]])
  t.deepEqual(b3.parentThenMasterLineage(),
    [[b3, "master"], [b2, "parent"], [a2, "master"], [Node, "end"]])
  t.deepEqual(c3.parentThenMasterLineage(),
    [[c3, "parent"], [b3, "master"], [b2, "parent"], [a2, "master"], [Node, "end"]])

  t.deepEqual(b.headThenMasterLineage(),
    [[b, "master"], [Node, "end"]])
  t.deepEqual(c.headThenMasterLineage(),
    [[c, "master"], [Node, "end"]])
  t.deepEqual(a2.headThenMasterLineage(),
    [[a2, "master"], [Node, "end"]])
  t.deepEqual(b2.headThenMasterLineage(),
    [[b2, "master"], [b, "master"], [Node, "end"]])
  t.deepEqual(c2.headThenMasterLineage(),
    [[c2, "head"], [b2, "master"], [b, "master"], [Node, "end"]])
  t.deepEqual(b3.headThenMasterLineage(),
    [[b3, "master"], [b2, "master"], [b, "master"], [Node, "end"]])
  t.deepEqual(c3.headThenMasterLineage(),
    [[c3, "head"], [b3, "master"], [b2, "master"], [b, "master"], [Node, "end"]])

  t.end()
