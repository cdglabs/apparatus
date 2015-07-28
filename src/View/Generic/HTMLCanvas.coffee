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

  _refresh: ->
    canvas = @getDOMNode()

    # TODO: For speed we should only sizeCanvas when it mounts or when it
    # really needs to be resized because getBoundingClientRect is expensive.
    # Instead we should just clear the canvas here.
    sizeCanvas(canvas)

    ctx = canvas.getContext("2d")
    ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0)

    @props.draw(ctx)
