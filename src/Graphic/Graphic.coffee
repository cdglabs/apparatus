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
    a {color, lineWidth} object or null.

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
  render: (opts) ->
    @highlightIfNecessary(opts)

  hitDetect: (opts) ->
    {x, y, viewMatrix} = opts
    [myX, myY] = viewMatrix.compose(@matrix).origin()
    distSq = (x - myX) * (x - myX) + (y - myY) * (y - myY)
    if distSq <= @highlightRadius * @highlightRadius
      return [@particularElement]
    else
      return null

  highlightIfNecessary: ({highlight, ctx, viewMatrix}) ->
    return unless highlight
    highlightSpec = highlight(this)
    if highlightSpec
      ctx.save()
      ctx.beginPath();
      [myX, myY] = viewMatrix.compose(@matrix).origin()
      ctx.arc(myX, myY, @highlightRadius, 0, 2 * Math.PI, false)
      ctx.fillStyle = highlightSpec.color
      ctx.fill()
      ctx.restore()

  highlightRadius: 5



class Graphic.Path extends Graphic.Element
  render: (opts) ->
    @buildPath(opts)
    @performPaintOps(opts)
    @highlightIfNecessary(opts)

    # Render anchor highlights, if necessary
    for childGraphic in @childGraphics
      childGraphic.render(opts)

  hitDetect: (opts) ->
    # Check for anchor hits
    latestHit = null
    for childGraphic in @childGraphics
      latestHit = childGraphic.hitDetect(opts) ? latestHit
    if latestHit
      console.log('path hit anchor!')
      return latestHit.concat(@particularElement)

    opts.ctx = getDummyCanvasCtx()
    {ctx, x, y} = opts
    @buildPath(opts)
    ctx.save()
    ctx.lineWidth = 5;
    hit = ctx.isPointInPath(x, y) or ctx.isPointInStroke(x, y)
    ctx.restore()
    if hit
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


class Graphic.Text extends Graphic.Path
  render: (opts) ->
    ctx = opts.ctx
    ctx.save()
    @setupText(opts)
    @renderText(opts)
    ctx.restore()
    if opts.highlight
      @buildPath(opts)
      @highlightIfNecessary(opts)

  textComponent: ->
    @componentOfType(Graphic.TextComponent)

  renderText: ({ctx}) ->
    {text} = @textComponent()
    ctx.fillText(text, 0, 0)

  textMultiplier: 100

  # setupText will set the appropriate font styles, color, and transformation
  # matrix so that text is ready to be rendered (fillText) at 0,0.
  setupText: ({ctx, viewMatrix}) ->
    {text, fontFamily, textAlign, textBaseline, color} = @textComponent()
    matrix = viewMatrix.compose(@matrix)
    matrix = matrix.scale(1 / @textMultiplier, -1 / @textMultiplier)
    matrix.canvasTransform(ctx)
    ctx.font = "#{@textMultiplier}px #{fontFamily}"
    ctx.textAlign = textAlign
    ctx.textBaseline = textBaseline
    ctx.fillStyle = color

  # Text's buildPath just draws a rectangle around the text's bounding
  # rectangle.
  buildPath: (opts) ->
    {ctx, viewMatrix} = opts
    ctx.save()
    @setupText(opts)

    {text, fontFamily, textAlign, textBaseline, color} = @textComponent()

    width = ctx.measureText(text).width / @textMultiplier
    height = 1
    ctx.restore()

    # TODO: Deal properly with ltr/rtl text.
    if textAlign == "left" or textAlign == "start"
      minX = 0
      maxX = width
    else if textAlign == "right" or textAlign == "end"
      minX = -width
      maxX = 0
    else if textAlign == "center"
      minX = -width / 2
      maxX =  width / 2

    # TODO: This 0.25 is hard-coded. How can this baseline value be determined
    # programmatically based on the font?
    baseline = 0.25
    if textBaseline == "top"
      minY = -height - baseline
      maxY = -baseline
    else if textBaseline == "middle"
      minY = (-height - baseline) / 2
      maxY = ( height + baseline) / 2
    else if textBaseline == "alphabetic"
      minY = -baseline
      maxY = height - baseline
    else if textBaseline == "bottom"
      minY = 0
      maxY = height

    # Draw the text bounding rectangle.
    ctx.save()
    matrix = viewMatrix.compose(@matrix)
    matrix.canvasTransform(ctx)
    ctx.beginPath()
    ctx.moveTo(minX, minY)
    ctx.lineTo(minX, maxY)
    ctx.lineTo(maxX, maxY)
    ctx.lineTo(maxX, minY)
    ctx.closePath()
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
