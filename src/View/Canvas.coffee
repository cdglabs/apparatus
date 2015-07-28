R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "Canvas",
  contextTypes:
    project: Model.Project

  render: ->
    R.div {
      className: "Canvas"
      # style:
      #   cursor: @_cursor()
      # onMouseDown: @_onMouseDown
      # onMouseEnter: @_onMouseEnter
      # onMouseLeave: @_onMouseLeave
      # onMouseMove: @_onMouseMove
      # onWheel: @_onWheel
    },
      R.HTMLCanvas {
        draw: @_draw
      }

  _draw: (ctx) ->
    element = @_viewedElement()
    viewMatrix = @_viewMatrix()

    # Should it be allGraphics?
    graphic = element.graphic()

    # @_paintBackgroundGrid(ctx)

    graphic.render({ctx, viewMatrix})

  _viewedElement: ->
    project = @context.project
    element = project.viewedElement
    return element

  _viewMatrix: ->
    el = @getDOMNode()
    rect = el.getBoundingClientRect()
    {width, height} = rect

    return new Util.Matrix(100, 0, 0, -100, width / 2, height / 2)
