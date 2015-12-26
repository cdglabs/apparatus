test = require "tape"
_ = require "underscore"


DeepEquality = require "../src/Util/DeepEquality"
cyclicDeepEqual = DeepEquality.cyclicDeepEqual


test "Primitive values work", (t) ->
  t.ok(cyclicDeepEqual(23, 23), "numbers")
  t.ok(cyclicDeepEqual(null, null), "null")
  t.notOk(cyclicDeepEqual(23, 24), "different numbers")
  t.end()

test "Simple objects work", (t) ->
  t.ok(cyclicDeepEqual({a: 23, b: 2233}, {a: 23, b: 2233}), "same")
  t.notOk(cyclicDeepEqual({a: 23, b: 100}, {a: 23, b: 2233}), "different value")
  t.notOk(cyclicDeepEqual({a: 23}, {a: 23, b: 2233}), "first object smaller")
  t.notOk(cyclicDeepEqual({a: 23, b: 2233}, {a: 23}), "seond object smaller")
  t.end()

test "Simple arrays work", (t) ->
  t.ok(cyclicDeepEqual([23, 2233], [23, 2233]), "same")
  t.notOk(cyclicDeepEqual([23, 100], [23, 2233]), "different value")
  t.notOk(cyclicDeepEqual([23], [23, 2233]), "first array smaller")
  t.notOk(cyclicDeepEqual([23, 2233], [23]), "second array smaller")
  t.end()

test "Compound objects work", (t) ->
  t.ok(cyclicDeepEqual(
    {a: {b: 23}, c: {d: 2233}},
    {a: {b: 23}, c: {d: 2233}}), "same")
  t.notOk(cyclicDeepEqual(
    {a: {b: 23}, c: {d: 2233}},
    {a: {b: 100}, c: {d: 2233}}), "different value (deep)")
  t.end()

test "Objects with multiply-referenced parts work", (t) ->
  # Make object with multiply-referenced part
  makeWith = ->
    a = {}
    b = {}
    a.x = b
    a.y = b
    return a

  # Make object without multiply-referenced part
  makeWithout = ->
    return {x: {}, y: {}}

  t.deepEqual(makeWith(), makeWithout(),  "objects are deep-equal as values")
  t.notOk(
    cyclicDeepEqual(makeWith(), makeWithout()),
    "objects are not cyclic-deep-equal")
  t.notOk(
    cyclicDeepEqual(makeWithout(), makeWith()),
    "objects are not cyclic-deep-equal")

  t.ok(
    cyclicDeepEqual(makeWith(), makeWith()),
    "first kind is cyclic-deep-equal to itself")
  t.ok(
    cyclicDeepEqual(makeWithout(), makeWithout()),
    "second kind is cyclic-deep-equal to itself")

  t.end()

test "Self- and mutually-referential objects work", (t) ->
  # Make self-referential object
  makeSelf = ->
    a = {}
    a.x = a
    return a

  # Make mutually-referential object
  makeMutually = ->
    a = {}
    b = {}
    a.x = b
    b.x = a
    return a

  # Note: makeSelf and makeMutually return infinitely deep objects which are
  # "equal as values" (so they are not caught as unequal by pop-equals, which
  # claims to compare cyclic objects).
  t.notOk(
    cyclicDeepEqual(makeSelf(), makeMutually()),
    "objects are not cyclic-deep-equal")
  t.notOk(
    cyclicDeepEqual(makeMutually(), makeSelf()),
    "objects are not cyclic-deep-equal")

  # And just to check:
  t.ok(
    cyclicDeepEqual(makeSelf(), makeSelf()),
    "first kind is cyclic-deep-equal to itself")
  t.ok(
    cyclicDeepEqual(makeMutually(), makeMutually()),
    "second kind is cyclic-deep-equal to itself")

  t.end()

test "Situation which tricks deep-equal-ident works", (t) ->
  # See https://github.com/fkling/deep-equal-ident/issues/3

  a = [[]]
  case1 = [a, a[0]]
  case2 = [a, []]

  t.deepEqual(case1, case2,  "objects are deep-equal as values")
  t.notOk(cyclicDeepEqual(case1, case2), "objects are not cyclic-deep-equal")
  t.notOk(cyclicDeepEqual(case2, case1), "objects are not cyclic-deep-equal")

  t.end()

test "Prototypes are checked appropriately", (t) ->
  make1 = ->
    a = {x: {}, y: {}}
    b = {}
    Object.setPrototypeOf(a.x, b)
    return a

  make2 = ->
    return {x: {}, y: {}}

  t.ok(
    cyclicDeepEqual(make1(), make2(), {checkPrototypes: false})
    "test objects are equal aside from prototypes")
  t.notOk(
    cyclicDeepEqual(make1(), make2())
    "test objects are not equal if you check prototypes")
  t.ok(
    cyclicDeepEqual(make1(), make1()),
    "first kind is cyclic-deep-equal to itself")
  t.ok(
    cyclicDeepEqual(make2(), make2()),
    "second kind is cyclic-deep-equal to itself")

  t.end()
