test = require "tape"

Node = require "../src/Model/Node"
Link = require "../src/Model/Link"

test "Links point analogously", (t) ->
  a = Node.createVariant()
  b = Node.createVariant()
  c = Node.createVariant()
  a.addChild(b)
  a.addChild(c)

  a2 = a.createVariant()
  [b2, c2] = a.children()

  l = Link.createVariant()
  b.addChild(l)
  l.setTarget(c)

  l2 = b2.children()[0]

  t.equal(l2.target(), c2)

  t.end()

###

TODO:

Test longer chains of variants (e.g. make a3)

###
