_ = require "underscore"
R = require "../R"


devicePixelRatio = window.devicePixelRatio || 1

sizeCanvas = (canvas) ->
  rect = canvas.getBoundingClientRect()
  canvas.width = rect.width * devicePixelRatio
  canvas.height = rect.height * devicePixelRatio


R.create "HTMLCanvas",
  propTypes:
    draw: Function

  render: ->
    props = {}
    _.defaults(props, @props)
    R.canvas props

  componentDidMount: -> @_refresh()
  componentDidUpdate: -> @_refresh()

  resize: ->
    @_canvasIsSized = false

  _refresh: ->
    canvas = R.findDOMNode(@)

    if @_canvasIsSized
      canvas.width = canvas.width
    else
      sizeCanvas(canvas)
      @_canvasIsSized = true

    ctx = canvas.getContext("2d")
    ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0)

    @props.draw(ctx)
