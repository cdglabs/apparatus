_ = require "underscore"
numeric = require "numeric"


module.exports = Util = {}
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

# textFocus returns a CodeMirror instance or a contenteditable DOM element
# that is focused or null if nothing is focused.
Util.textFocus = ->
  if el = document.querySelector(".CodeMirror-focused")
    return el.CodeMirror
  if document.activeElement?.isContentEditable
    return document.activeElement
  return null

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
  return Util.assignId(object, Util.generateId())

Util.assignId = (object, id) ->
  return object.id = id

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
  if !_.all(startArgs, (arg) => _.isFinite(arg))
    console.error(startArgs)
    throw "Bad startArgs!"
  uncmin = numeric.uncmin(objective, startArgs)
  if isNaN(uncmin.f)
    console.warn "NaN"
    return startArgs
  else
    solution = uncmin.solution
    return solution

Util.clamp = (x, min, max) ->
  Math.max(min, Math.min(max, x))

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


# =============================================================================
# String
# =============================================================================

# stringMatchIndices searches haystack string for the needle string and
# returns all of the indices where it's found.
Util.stringMatchIndices = (haystack, needle) ->
  indices = []
  cursor = -1
  while true
    cursor = haystack.indexOf(needle, cursor+1)
    break if cursor == -1
    indices.push(cursor)
  return indices

# CodeMirror likes working with {line, ch} objects but sometimes it's easier
# to work with just a straight character index. This function converts a
# character index to a {line, ch} by counting new lines in the string.
Util.charToLineCh = (string, char) ->
  stringUpToChar = string.substr(0, char)
  lines = stringUpToChar.split("\n")
  return {line: lines.length-1, ch: _.last(lines).length}

Util.numberFragment =
  "[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?"
Util.numberRegExp =
  new RegExp("^#{Util.numberFragment}$")
Util.rangedNumberRegExp =
  new RegExp("^(#{Util.numberFragment}){(#{Util.numberFragment})-(#{Util.numberFragment})}$")

Util.isNumberString = (string) ->
  return Util.numberRegExp.test(string)

Util.matchRangedNumberString = (string) ->
  maybeMatch = string.match(Util.rangedNumberRegExp)
  if not maybeMatch then return maybeMatch  # no match
  return {
    valueStr: maybeMatch[1]
    lowStr: maybeMatch[3]
    highStr: maybeMatch[5]
  }

Util.isStringLiteral = (string) ->
  return /^(?:"(?:\\"|[^"\r\n])*"|'(?:\\'|[^'\r\n])*')$/.test(string)

Util.isKeywordLiteral = (string) ->
  return (
    string == "true" or string == "false" or
    string == "null" or string == "undefined"
  )

Util.escapeHtml = (str) ->
  div = document.createElement("div")
  div.appendChild(document.createTextNode(str))
  return div.innerHTML
