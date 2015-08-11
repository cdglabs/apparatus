_ = require "underscore"
numeric = require "numeric"


module.exports = Util = {}

Util.jsEvaluate = require "./jsEvaluate"
Util.Matrix = require "./Matrix"


# =============================================================================
# DOM
# =============================================================================

Util.matches = (el, selector) ->
  matchesSelector = Element::webkitMatchesSelector ? Element::mozMatchesSelector ? Element::oMatchesSelector
  matchesSelector.call(el, selector)

Util.closest = (el, selector) ->
  return undefined unless el? and el.nodeType == Node.ELEMENT_NODE

  if _.isString(selector)
    fn = (el) -> Util.matches(el, selector)
  else
    fn = selector

  if fn(el)
    return el
  else
    parent = el.parentNode
    return Util.closest(parent, fn)


# =============================================================================
# DOM Events
# =============================================================================

Util.mouseDownPreventDefault = (e) ->
  e.preventDefault()
  document.activeElement.blur()
  window.getSelection().removeAllRanges()
  document.body.focus()

  # Unfocus any focused Code Mirrors
  for el in document.querySelectorAll(".CodeMirror-focused")
    el.CodeMirror.getInputField().blur()

Util.clearTextFocus = ->
  document.activeElement.blur()
  window.getSelection().removeAllRanges()
  document.body.focus()

  # Unfocus any focused Code Mirrors
  for el in document.querySelectorAll(".CodeMirror-focused")
    el.CodeMirror.getInputField().blur()


# =============================================================================
# IDs
# =============================================================================

Util.getId = (object) ->
  return object.id if object.hasOwnProperty("id")
  return object.id = Util.generateId()

counter = 0
Util.generateId = ->
  return "id" +
    Math.random().toString(36).substr(2, 6) +
    Date.now().toString(36) +
    (counter++).toString(36)


# =============================================================================
# Numeric
# =============================================================================

Util.quadrance = (p1, p2) ->
  d = numeric['-'](p1, p2)
  numeric.dot(d, d)

Util.solve = (objective, startArgs) ->
  uncmin = numeric.uncmin(objective, startArgs)
  if isNaN(uncmin.f)
    console.warn "NaN"
    return startArgs
  else
    solution = uncmin.solution
    return solution


# =============================================================================
# Precision
# =============================================================================

Util.precision = (x) ->
  x = ""+x
  # TODO: Deal with eE stuff.
  decimalIndex = x.indexOf(".")
  return 0 if decimalIndex == -1
  return x.length - decimalIndex - 1

Util.toPrecision = (x, precision) ->
  x = Util.roundToPrecision(x, precision)
  return x.toFixed(precision)

Util.toMaxPrecision = (x, precision) ->
  x = Util.toPrecision(x, precision)
  if x.indexOf(".")
    x = x.replace(/\.?0+$/, "")
  return x

Util.roundToPrecision = (x, precision) ->
  multiplier = Math.pow(10, precision)
  x = Math.round(x * multiplier) / multiplier
  return x
