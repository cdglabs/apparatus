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

test "Dependencies work", (t) ->
  a = Attribute.createVariant({label: 'a'})
  b = Attribute.createVariant({label: 'b'})
  c = Attribute.createVariant({label: 'c'})

  a.setExpression("$$$b$$$ * 2", {$$$b$$$: b})
  b.setExpression("$$$c$$$ * 3", {$$$c$$$: c})
  c.setExpression("20")

  t.equal(a.value(), 120, 'value works')
  t.deepEqual(a.dependencies(), [b, c], 'dependencies works')
  t.equal(a.checkForCircularReferenceError(), null, 'checkForCircularReferenceError works')
  t.end()

test "Dependencies work with circular references", (t) ->
  a = Attribute.createVariant({label: 'a'})
  b = Attribute.createVariant({label: 'b'})
  c = Attribute.createVariant({label: 'c'})

  a.setExpression("$$$b$$$", {$$$b$$$: b})
  b.setExpression("$$$c$$$", {$$$c$$$: c})
  c.setExpression("$$$b$$$", {$$$b$$$: b})

  expectedError = new Attribute.CircularReferenceError([a, b, c, b])

  t.deepEqual(a.value(), expectedError, 'value works')
  t.deepEqual(a.dependencies(), [b, c], 'dependencies works')
  t.deepEqual(a.checkForCircularReferenceError(), expectedError, 'checkForCircularReferenceError works')
  t.end()
