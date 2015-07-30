module.exports = Graphic = {}


class Graphic.Element
  ###

  Each Graphic.Element must have these properties:

  matrix: a Util.Matrix that is the graphic's accumulated transformation.

  components: a list of Graphic.Component's representing the paint operations
  to perform.

  childGraphics: a list of Graphic.Element's.

  ###

  render: (opts) ->
    ###
    Opts:

    ctx: Canvas 2D context to render into.

    viewMatrix:

    highlight(graphic): A function that takes in a graphic and returns either
    a color or null.

    ###
    throw "Not implemented"

  hitDetect: (opts) ->
    ###
    Opts:

    x, y: Position to hit detect.

    shouldDetectAnchor(anchor): A function that takes in an anchor graphic and
    returns true or false whether to hit detect that anchor.

    ###
    throw "Not implemented"


class Graphic.Group extends Graphic.Element

class Graphic.Anchor extends Graphic.Element




class Graphic.Path extends Graphic.Element
  render: (opts) ->
    @buildPath(opts)
    @performPaintOps(opts)
    @highlightIfNecessary(opts)

  performPaintOps: ({ctx}) ->
    for component in @components
      if component instanceof Graphic.PaintOp
        component.paint(ctx)

  highlightIfNecessary: ({highlight, ctx}) ->
    return unless highlight
    highlightSpec = highlight(this)
    if highlightSpec
      ctx.save()
      ctx.strokeStyle = highlightSpec.color
      ctx.lineWidth = highlightSpec.lineWidth
      ctx.stroke()
      ctx.restore()

  buildPath: ({ctx, viewMatrix}) ->
    ctx.beginPath()
    anchors = @collectAnchors()
    for anchor in anchors
      [x, y] = viewMatrix.compose(anchor.matrix).origin()
      ctx.lineTo(x, y)

    if @isClosed()
      ctx.closePath()

  collectAnchors: ->
    anchors = []
    collect = (graphic) ->
      if graphic instanceof Graphic.Anchor
        anchors.push(graphic)
      else if graphic instanceof Graphic.Group
        collectChildrenOf(graphic)
    collectChildrenOf = (graphic) ->
      for childGraphic in graphic.childGraphics
        collect(childGraphic)
    collectChildrenOf(this)
    return anchors

  isClosed: ->
    # TODO
    return true


class Graphic.Component

class Graphic.PaintOp extends Graphic.Component

class Graphic.Fill extends Graphic.PaintOp
  paint: (ctx) ->
    ctx.save()
    ctx.fillStyle = @color
    ctx.fill()
    ctx.restore()

class Graphic.Stroke extends Graphic.PaintOp
  paint: (ctx) ->
    return if @lineWidth <= 0
    ctx.save()
    ctx.strokeStyle = @color
    ctx.lineWidth = @lineWidth
    ctx.stroke()
    ctx.restore()
