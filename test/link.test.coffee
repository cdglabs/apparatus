test = require "tape"

node = require "../src/Model/node"
link = require "../src/Model/link"

test "Links point analogously", (t) ->
  a = node.createVariant()
  b = node.createVariant()
  c = node.createVariant()
  a.addChild(b)
  a.addChild(c)

  a2 = a.createVariant()
  [b2, c2] = a.children()

  l = link.createVariant()
  b.addChild(l)
  l.setTarget(c)

  l2 = b2.children()[0]

  t.equal(l2.target(), c2)

  t.end()

###

TODO:

Test longer chains of variants (e.g. make a3)

###
