test = require "tape"
Model = require "../src/Model/Model"
Attribute = Model.Attribute

test "Numbers work", (t) ->
  a = Attribute.createVariant()
  a.setExpression("6")
  t.equal(a.value(), 6)
  t.end()

test "Math expressions work", (t) ->
  a = Attribute.createVariant()
  a.setExpression("5 + 5")
  t.equal(a.value(), 10)
  t.end()

test "References work", (t) ->
  a = Attribute.createVariant()
  b = Attribute.createVariant()

  a.setExpression("20")
  b.setExpression("$$$a$$$ * 2", {$$$a$$$: a})

  t.equal(b.value(), 40)
  t.end()

test "Changes recompile", (t) ->
  a = Attribute.createVariant()
  b = Attribute.createVariant()

  a.setExpression("20")
  b.setExpression("$$$a$$$ * 2", {$$$a$$$: a})

  t.equal(b.value(), 40)

  a.setExpression("10")
  t.equal(b.value(), 20)

  b.setExpression("$$$a$$$ * 3", {$$$a$$$: a})
  t.equal(b.value(), 30)
  t.end()
