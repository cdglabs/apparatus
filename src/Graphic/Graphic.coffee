_ = require "underscore"

module.exports = Graphic = {}


# =============================================================================
# Base Element
# =============================================================================

class Graphic.Element
  ###

  Each Graphic.Element must have these properties:

  particularElement: The ParticularElement that generated the graphic. This is
  used for "back tracing" what part of the model generated this graphic, e.g.
  to implement selection when you click a shape on the canvas.

  matrix: a Util.Matrix that is the graphic's *accumulated* transformation.

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

    Given (x,y), returns null if there is nothing under (x,y), that is (x,y)
    is a background pixel. Otherwise returns a list of ParticularElements which are
    under (x,y). The list goes in order of deepest to shallowest. So assuming
    there's a hit: the first ParticularElement is the deepest one that is under (x,y)
    and the last ParticularElement is (necessarily) this.particularElement.

    Opts:

    x, y: Position to hit detect.

    viewMatrix:

    shouldDetectAnchor(anchor): A function that takes in an anchor graphic and
    returns true or false whether to hit detect that anchor.

    ###
    throw "Not implemented"


  # ===========================================================================
  # Helpers
  # ===========================================================================

  componentOfType: (type) ->
    _.find @components, (component) -> component instanceof type

  componentsOfType: (type) ->
    _.filter @components, (component) -> component instanceof type


# =============================================================================
# Elements
# =============================================================================

class Graphic.Group extends Graphic.Element
  render: (opts) ->
    for childGraphic in @childGraphics
      childGraphic.render(opts)

  hitDetect: (opts) ->
    # TODO: test
    latestHit = null
    for childGraphic in @childGraphics
      latestHit = childGraphic.hitDetect(opts) ? latestHit
    if latestHit
      return latestHit.concat(@particularElement)
    else
      return null



class Graphic.Anchor extends Graphic.Element




class Graphic.Path extends Graphic.Element
  render: (opts) ->
    @buildPath(opts)
    @performPaintOps(opts)
    @highlightIfNecessary(opts)

  hitDetect: (opts) ->
    opts.ctx = getDummyCanvasCtx()
    {ctx, x, y} = opts
    @buildPath(opts)
    if ctx.isPointInPath(x, y)
      return [@particularElement]
    else
      return null

  performPaintOps: ({ctx}) ->
    for component in @componentsOfType(Graphic.PaintOp)
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
    pathComponent = @componentOfType(Graphic.PathComponent)
    return pathComponent.closed


class Graphic.Circle extends Graphic.Path
  buildPath: ({ctx, viewMatrix}) ->
    ctx.beginPath()
    ctx.save()
    matrix = viewMatrix.compose(@matrix)
    matrix.canvasTransform(ctx)
    ctx.arc(0, 0, 1, 0, 2 * Math.PI, false)
    ctx.restore()


# =============================================================================
# Components
# =============================================================================

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

class Graphic.PathComponent extends Graphic.Component

class Graphic.TextComponent extends Graphic.Component

# =============================================================================
# Dummy Canvas
# =============================================================================

# This dummy canvas is used to perform isPointInPath for hit detection.

dummyCanvasCtx = null
getDummyCanvasCtx = ->
  return dummyCanvasCtx if dummyCanvasCtx
  dummyCanvas = document.createElement("canvas")
  return dummyCanvasCtx = dummyCanvas.getContext("2d")
