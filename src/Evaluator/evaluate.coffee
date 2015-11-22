module.exports = evaluate = (jsString) ->
  return eval(jsString)


# =============================================================================
# Built-in Functions
# =============================================================================

E = Math.E
LN2 = Math.LN2
LN10 = Math.LN10
LOG2E = Math.LOG2E
LOG10E = Math.LOG10E
PI = Math.PI
SQRT1_2 = Math.SQRT1_2
SQRT2 = Math.SQRT2
TAU = Math.PI * 2

abs = Math.abs
acos = Math.acos
asin = Math.asin
atan = Math.atan
atan2 = Math.atan2
ceil = Math.ceil
cos = Math.cos
exp = Math.exp
floor = Math.floor
log = Math.log
max = Math.max
min = Math.min
pow = Math.pow
random = Math.random
round = Math.round
sin = Math.sin
sqrt = Math.sqrt
tan = Math.tan

rgba = (r, g, b, a) ->
  r = Math.round(r * 255)
  g = Math.round(g * 255)
  b = Math.round(b * 255)
  return "rgba(#{r}, #{g}, #{b}, #{a})"

spread = require "./spread"

_ = require "underscore"
