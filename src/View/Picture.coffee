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
      if hoverManager.controllerParticularElement?.isAncestorOf(particularElement)
        return {color: "#c00", lineWidth: 2.5}
      if project.selectedParticularElement?.isAncestorOf(particularElement)
        return {color: "#09c", lineWidth: 2.5}
      if hoverManager.hoveredParticularElement?.isAncestorOf(particularElement)
        return {color: "#0c9", lineWidth: 2.5}

    renderOpts = {ctx, viewMatrix, highlight}

    for graphic in element.allGraphics()
      graphic.render(renderOpts)

  _viewMatrix: ->
    {element} = @props
    {width, height} = @_size()
    screenMatrix = new Util.Matrix(0.1, 0, 0, -0.1, width / 2, height / 2)
    elementViewMatrix = element.viewMatrix
    return screenMatrix.compose(elementViewMatrix)

  _size: ->
    return @_cachedSize if @_cachedSize
    el = R.findDOMNode(@)
    rect = el.getBoundingClientRect()
    {width, height} = rect
    return @_cachedSize = {width, height}
