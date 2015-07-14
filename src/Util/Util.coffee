_ = require "underscore"


module.exports = Util = {}

Util.jsEvaluate = require "./jsEvaluate"


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

