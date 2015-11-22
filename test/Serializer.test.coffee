test = require "tape"
_ = require "underscore"


Serializer = require "../src/Storage/Serializer"
DeepEquality = require "../src/Util/DeepEquality"
{cyclicDeepEqual} = DeepEquality


roundTrip = (value) ->
  serializer = new Serializer([])
  serializedObject = serializer.jsonify(value)
  serializedString = JSON.stringify(serializedObject)

  deserializer = new Serializer([])
  deserializedString = JSON.parse(serializedString)
  deserializedObject = deserializer.dejsonify(deserializedString)

  return deserializedObject

testRoundTrip = (t, value) ->
  # Note: Since serializing actually mutates the original object by adding IDs,
  # we don't have to strip IDs from the output.

  # TODO: We should be skeptical of the fact that serializing mutates the
  # original object.

  roundTripValue = roundTrip(value)
  t.ok(
    cyclicDeepEqual(value, roundTripValue),
    "round trip value should equal original value")

stripIds = (value) ->
  if _.isArray(value)
    return (stripIds(subValue) for subValue in value)
  else if _.isObject(value)
    return _.mapObject(_.omit(value, 'id'), stripIds)
  else
    return value

test "Primitive values work", (t) ->
  testRoundTrip(t, 23)
  testRoundTrip(t, "primitive string")
  testRoundTrip(t, false)
  testRoundTrip(t, undefined)
  testRoundTrip(t, null)
  t.end()

test "Simple objects work", (t) ->
  testRoundTrip(t, {a: 23})
  t.end()

test "Compound objects work", (t) ->
  testRoundTrip(t, {a: {b: 23}, c: {d: 2233}})
  t.end()

test "Objects with multiply-referenced parts work", (t) ->
  a = {}
  b = {}
  a.x = b
  a.y = b
  testRoundTrip(t, a)
  t.end()

test "Self-referential objects work", (t) ->
  a = {}
  a.x = a
  testRoundTrip(t, a)
  t.end()

test "Mutually-referential objects work", (t) ->
  a = {}
  b = {}
  a.x = b
  b.x = a
  testRoundTrip(t, a)
  t.end()

test "Prototypes are serialized", (t) ->
  a = {x: 10}
  b = {y: 10}
  Object.setPrototypeOf(a, b)
  testRoundTrip(t, a)
  t.end()

test "Double-underscored properties are not serialized", (t) ->
  a = {x: 10, __secret: "my secret"}
  aActual = stripIds(roundTrip(a))
  aExpected = {x: 10}
  t.ok(cyclicDeepEqual(aActual, aExpected))
  t.end()

test "Functions are not serialized", (t) ->
  a = {x: 10, y: (a) -> a * a}
  aActual = stripIds(roundTrip(a))
  aExpected = {x: 10}
  t.ok(cyclicDeepEqual(aActual, aExpected))
  t.end()

test "Builtins work", (t) ->
  secretCode = "ABRACADABRA"

  builtin = {secretCode: secretCode}
  a = {x: builtin}

  serializer = new Serializer([builtin])
  serializedObject = serializer.jsonify(a)
  serializedString = JSON.stringify(serializedObject)

  t.equal(
    serializedString.indexOf("ABRACADABRA"), -1,
    "serialized object does not contain secret word")

  deserializer = new Serializer([builtin])
  deserializedString = JSON.parse(serializedString)
  deserializedObject = deserializer.dejsonify(deserializedString)

  t.ok(
    cyclicDeepEqual(a, deserializedObject),
    "deserialized object equals original object")

  t.end()
