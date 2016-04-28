_ = require "underscore"
R = require "../R"

R.create "EditableText",
  propTypes:
    value: String
    setValue: Function

  shouldComponentUpdate: (nextProps) ->
    return @_isDirty or nextProps.value != @props.value

  render: ->
    props = {
      contentEditable: true
      onInput: @_onInput
      onKeyDown: @_onKeyDown
    }
    _.defaults(props, @props)
    R.div props

  componentDidMount: ->
    @_refresh()
    # Autofocus if empty string value.
    if @props.value == "" or !@props.value
      R.findDOMNode(@).focus()

  componentDidUpdate: ->
    @_refresh()

  _refresh: ->
    el = R.findDOMNode(@)
    if el.textContent != @props.value
      el.textContent = @props.value
    @_isDirty = false

  _onInput: ->
    @_isDirty = true
    el = R.findDOMNode(@)
    newValue = el.textContent
    @props.setValue(newValue)

  _onKeyDown: (e) ->
    if e.keyCode == 13 # Enter
      e.preventDefault()
