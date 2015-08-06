R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "Thumbnail",
  propTypes:
    element: Model.Element

  render: ->
    element = @props.element
    R.div {className: "Thumbnail"},
      R.Picture {element}





R.create "Picture",
  contextTypes:
    project: Model.Project
    hoverManager: R.HoverManager

  propTypes:
    element: Model.Element

  render: ->
    R.HTMLCanvas {
      draw: @_draw
    }

  _draw: (ctx) ->
    project = @context.project
    hoverManager = @context.hoverManager
    element = @props.element
    viewMatrix = @_viewMatrix()

    highlight = (graphic) ->
      particularElement = graphic.particularElement
      if project.selectedParticularElement?.isAncestorOf(particularElement)
        return {color: "#09c", lineWidth: 2.5}
      if hoverManager.hoveredParticularElement?.isAncestorOf(particularElement)
        return {color: "#0c9", lineWidth: 2.5}

    renderOpts = {ctx, viewMatrix, highlight}

    for graphic in element.allGraphics()
      graphic.render(renderOpts)

  _viewMatrix: ->
    el = @getDOMNode()
    rect = el.getBoundingClientRect()
    {width, height} = rect

    return new Util.Matrix(10, 0, 0, -10, width / 2, height / 2)

