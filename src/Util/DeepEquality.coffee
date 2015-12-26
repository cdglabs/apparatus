_ = require "underscore"


module.exports = DeepEquality = {}


# cyclicDeepEqual compares two Javascript values. It is comfortable with values
# which have cyclic references between their parts. In this case, it will ensure
# that the two values have isomorphic reference graphs.
#   Opts:
#     checkPrototypes (default: true) -- whether equality of prototypes should
#       be included in the checking process
DeepEquality.cyclicDeepEqual = (a, b, opts) ->
  # This code is adapted from Anders Kaseorg's post at
  # http://stackoverflow.com/a/32794387/668144.

  # Note that deep-equal-ident should not be used unless
  # https://github.com/fkling/deep-equal-ident/issues/3
  # is fixed.

  opts ?= {}
  _.defaults(opts, {
    checkPrototypes: true,
  })

  left = []
  right = []
  has = Object.prototype.hasOwnProperty

  visit = (a, b) ->
    if typeof a != 'object' || typeof b != 'object' || a == null || b == null
      return a == b

    for i in [0...left.length]
      if (a == left[i])
        return b == right[i]
      if (b == right[i])
        return a == left[i]

    for own k of a
      return false if !has.call(b, k)
    for own k of b
      return false if !has.call(a, k)

    left.push(a)
    right.push(b)

    for own k of a
      return false if !visit(a[k], b[k])

    if opts.checkPrototypes
      # NOTE: This is changed from StackOverflow version, to allow prototypes to
      # be part of the maybe-isomorphic reference graphs rather than strictly
      # equal to one another.
      return false if !visit(Object.getPrototypeOf(a), Object.getPrototypeOf(b))

    return true

  return visit(a, b)
