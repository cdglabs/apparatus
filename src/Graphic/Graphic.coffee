_ = require "underscore"
Util = require "../Util/Util"


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

  toSvg: (opts) ->
    ###

    Returns an svg for the graphic as a string. The svg string does not have a
    wrapper <svg> element.

    Opts:

    viewMatrix:

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

  toSvg: (opts) ->
    svgString = ""
    for childGraphic in @childGraphics
      svgString += childGraphic.toSvg(opts)
    return svgString


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
    ctx.save()
    ctx.lineWidth = 5;
    hit = ctx.isPointInPath(x, y) or ctx.isPointInStroke(x, y)
    ctx.restore()
    if hit
      return [@particularElement]
    else
      return null

  toSvg: ({viewMatrix}) ->
    anchors = @collectAnchors()
    pointStrings = []
    for anchor in anchors
      [x, y] = viewMatrix.compose(anchor.matrix).origin()
      pointStrings.push("#{x},#{y}")
    pointsAttribute = "points=\"#{pointStrings.join(" ")}\""
    paintAttributes = @svgPaintAttributes()
    elementName = if @isClosed() then "polygon" else "polyline"
    return "<#{elementName} #{pointsAttribute} #{paintAttributes} />"


  performPaintOps: ({ctx, viewMatrix}) ->
    ctx.save()
    ctx.filter = @filter
    matrix = viewMatrix.compose(@matrix)
    for component in @componentsOfType(Graphic.PaintOp)
      component.paint(ctx, matrix)
    ctx.restore()

  svgPaintAttributes: ->
    # Note: below needs to be fixed once Elements are allowed to have multiple
    # fill, stroke, etc. Components.
    fillAttribute = @componentOfType(Graphic.Fill).toSvg()
    strokeAttribute = @componentOfType(Graphic.Stroke).toSvg()
    return "#{fillAttribute} #{strokeAttribute}"

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

  toSvg: ({viewMatrix}) ->
    matrix = viewMatrix.compose(@matrix)
    # TODO: In canvas we can transform a path without transforming a stroke.
    # In SVG, the only way to do this is with the vector-effect attribute. But
    # that is not supported in SVG 1.1, and I want this to work with CairoSVG,
    # laser cutter, etc. So for now, I'm just going to assume all circles are
    # transformed with only translation, rotation, and uniform scaling; not
    # the more general case of all affine transformations.
    r = Math.sqrt(matrix.a*matrix.a + matrix.b*matrix.b)
    cx = matrix.e
    cy = matrix.f
    paintAttributes = @svgPaintAttributes()
    return "<circle cx=\"#{cx}\" cy=\"#{cy}\" r=\"#{r}\" #{paintAttributes} />"



class Graphic.Text extends Graphic.Path
  render: (opts) ->
    ctx = opts.ctx

    ctx.save()
    ctx.filter = @filter

    @setupText(opts)
    @renderText(opts)

    ctx.restore()

    if opts.highlight
      @buildPath(opts)
      @highlightIfNecessary(opts)

  toSvg: ({viewMatrix}) ->
    # TODO
    return ""

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


class Graphic.Image extends Graphic.Path
  render: (opts) ->
    {imageCache} = opts
    {url} = @imageComponent()

    if not _.isString(url)
      return  # TODO: error reporting?

    imageCache.get(url, (image) => @drawImage(opts, image))

  imageComponent: ->
    @componentOfType(Graphic.ImageComponent)

  fullMatrix: (opts, image) ->
    {viewMatrix} = opts

    scale = 0.01
    matrix =
      viewMatrix
      .compose(@matrix)
      .compose(new Util.Matrix(scale, 0, 0, -scale, 0, scale * image.height))

  drawImage: (opts, image) ->
    {ctx} = opts
    matrix = @fullMatrix(opts, image)

    ctx.save()
    matrix.canvasTransform(ctx)
    ctx.filter = @filter

    ctx.drawImage(image, 0, 0)

    ctx.restore()

    ctx.save()
    matrix.canvasTransform(ctx)

    if opts.highlight
      ctx.beginPath()
      ctx.moveTo(0, 0)
      ctx.lineTo(0, image.height)
      ctx.lineTo(image.width, image.height)
      ctx.lineTo(image.width, 0)
      ctx.closePath()
      @highlightIfNecessary(opts)

    ctx.restore()

  hitDetect: (opts) ->
    {imageCache} = opts
    {url} = @imageComponent()

    image = imageCache.getSync(url)
    if not image
      return null

    matrix = @fullMatrix(opts, image)
    {x, y} = opts
    [localX, localY] = matrix.toLocal([x, y])
    if not (0 <= localX <= image.width) or not (0 <= localY <= image.height)
      return null

    ctx = getDummyCanvasCtx()
    ctx.canvas.width  = window.innerWidth;
    ctx.canvas.height = window.innerHeight;

    opts.ctx = ctx
    @drawImage(opts, image)
    pixel = ctx.getImageData(x, y, 1, 1).data

    if pixel[3] > 0  # alpha layer
      return [@particularElement]
    else
      return null


# =============================================================================
# Components
# =============================================================================

class Graphic.Component

class Graphic.PaintOp extends Graphic.Component

class Graphic.Fill extends Graphic.PaintOp
  paint: (ctx) ->
    unless @isTransparent()
      ctx.save()
      ctx.fillStyle = @color
      ctx.fill()
      ctx.restore()

  toSvg: ->
    if @isTransparent()
      return "fill=\"none\""
    else
      return "fill=\"#{@color}\""

  isTransparent: ->
    return @color == "transparent" or /^rgba\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*,\s*0\s*\)$/.test(@color)

class Graphic.Stroke extends Graphic.PaintOp
  paint: (ctx, matrix) ->
    return if @lineWidth <= 0
    ctx.save()
    if @scale
      matrix.canvasTransform(ctx)
    ctx.strokeStyle = @color
    ctx.lineWidth = @lineWidth
    ctx.stroke()
    ctx.restore()

  toSvg: ->
    return "stroke=\"#{@color}\" stroke-width=\"#{@lineWidth}\""

class Graphic.PathComponent extends Graphic.Component

class Graphic.TextComponent extends Graphic.Component

class Graphic.ImageComponent extends Graphic.Component

# =============================================================================
# Dummy Canvas
# =============================================================================

# This dummy canvas is used to perform isPointInPath for hit detection.

dummyCanvasCtx = null
getDummyCanvasCtx = ->
  return dummyCanvasCtx if dummyCanvasCtx
  dummyCanvas = document.createElement("canvas")
  return dummyCanvasCtx = dummyCanvas.getContext("2d")
