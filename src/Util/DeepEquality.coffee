_ = require "underscore"


module.exports = DeepEquality = {}


# Terminology: A "part" of a JS value is an object or array accessible from the
# value through recursive property access (including array indexing). If we
# like, we can also include prototype access as part of our recursive process,
# though its best to ignore the boring prototype Object.prototype.


# cyclicDeepEqual compares two Javascript values. It is comfortable with values
# which have cyclic references between their parts. In this case, it will ensure
# that the two values have isomorphic reference graphs.
DeepEquality.cyclicDeepEqual = (a, b, opts) ->
  # PLAN:
  # Recursively check that each piece of a matches a corresponding piece of b.
  # checkPartsEqual should do real work for each part aPart of a only once. This
  # is possible with the following strategy:
  #  * The first time checkPartsEqual is called on aPart, it checks that bPart
  #    is a valid, unclaimed part of b, and then records the association between
  #    aPart and bPart in an array called aPartToBPart. (This all happens before
  #    any recursive calls.)
  #  * If checkPartsEqual is called on aPart a second time, this is the result
  #    of either a cyclic reference during the checking of aPart, or the
  #    checking of some unrelated part of a. In either case, it suffices to
  #    check that bPart matches the part of b previously recorded in
  #    aPartToBPart.

  opts ?= {}
  _.defaults(opts, {
    log: false,
    checkPrototypes: true,
  })

  context = {
    aParts: _extractParts(a, opts),
    bParts: _extractParts(b, opts),
    aPartToBPart: [],
  }

  if context.log then console.log 'aParts', context.aParts
  if context.log then console.log 'bParts', context.bParts

  return _checkValuesEqual(a, b, opts, context)


_extractParts = (value, opts, toReturn = []) ->
  {checkPrototypes} = opts

  if _.isArray(value)
    if toReturn.indexOf(value) != -1
      return
    toReturn.push(value)
    for subValue in value
      _extractParts(subValue, opts, toReturn)
  else if _.isObject(value)
    if toReturn.indexOf(value) != -1
      return
    toReturn.push(value)
    for key, subValue of value
      _extractParts(subValue, opts, toReturn)
    if checkPrototypes
      valuePrototype = Object.getPrototypeOf(value)
      if valuePrototype != Object.prototype
        _extractParts(valuePrototype, opts, toReturn)
  return toReturn


# For this helper, aValue should be a part of a or a primitive value.
_checkValuesEqual = (aValue, bValue, opts, context) ->
  {log} = opts
  {aParts, bParts, aPartToBPart} = context

  if log then console.log 'checkValuesEqual', aValue, bValue
  if _.isArray(aValue) or _.isObject(aValue)
    return _checkPartsEqual(aValue, bValue, opts, context)
  else
    return aValue == bValue

# For this helper, aPart should be a part of a.
_checkPartsEqual = (aPart, bPart, opts, context) ->
  {log, checkPrototypes} = opts
  {aParts, bParts, aPartToBPart} = context

  if log then console.log 'checkPartsEqual', aPart, bPart

  aPartIndex = aParts.indexOf(aPart)
  if log then console.log '  aPartIndex', aPartIndex

  bPartIndex = bParts.indexOf(bPart)
  if log then console.log '  bPartIndex', bPartIndex
  if aPartToBPart[aPartIndex]?
    # aPart has a corresponding bPart recorded in aPartToBPart. This is all we
    # need to check.
    return aPartToBPart[aPartIndex] == bPartIndex

  if aPartToBPart.indexOf(bPartIndex) != -1
    # bPart is already claimed by a different a part!
    return false

  aPartToBPart[aPartIndex] = bPartIndex

  if _.isArray(aPart)
    if !_.isArray(bPart)
      return false
    if aPart.length != bPart.length
      return false
    for aSubValue, i in aPart
      if !_checkValuesEqual(aSubValue, bPart[i], opts, context)
        return false
    return true
  else if _.isObject(aPart)
    if !_.isObject(bPart)
      return false
    if _.keys(aPart).length != _.keys(bPart).length
      return false
    for own key, aSubValue of aPart
      if !_checkValuesEqual(aSubValue, bPart[key], opts, context)
        return false
    if checkPrototypes
      aPartProto = Object.getPrototypeOf(aPart)
      bPartProto = Object.getPrototypeOf(bPart)
      if !(aPartProto == Object.prototype and bPartProto == Object.prototype)
        # one of them is interesting!
        if aPartProto == Object.prototype or bPartProto == Object.prototype
          # one of them isn't interesting!
          return false
        if !_checkValuesEqual(aPartProto, bPartProto, opts, context)
          return false

    return true
