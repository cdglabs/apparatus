_ = require "underscore"


module.exports = Util = {}

Util.jsEvaluate = require "./jsEvaluate"


# =============================================================================
# DOM
# =============================================================================

matchesSelector = Element::webkitMatchesSelector ? Element::mozMatchesSelector ? Element::oMatchesSelector

Util.matches = (el, selector) ->
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




