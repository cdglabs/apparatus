module.exports = class Matrix
  constructor: (@a=1, @b=0, @c=0, @d=1, @e=0, @f=0) ->

  translate: (x, y) ->
    @transform(1, 0, 0, 1, x, y)

  scale: (x, y) ->
    @transform(x, 0, 0, y, 0, 0)

  rotate: (angle) ->
    c = Math.cos(angle)
    s = Math.sin(angle)
    @transform(c, s, -s, c, 0, 0)

  transform: (a, b, c, d, e, f) ->
    new Matrix(
      @a * a + @c * b
      @b * a + @d * b
      @a * c + @c * d
      @b * c + @d * d
      @a * e + @c * f + @e
      @b * e + @d * f + @f
    )

  compose: (m) ->
    @transform(m.a, m.b, m.c, m.d, m.e, m.f)

  inverse: ->
    return @_inverse if @_inverse?
    ad_minus_bc = @a * @d - @b * @c
    bc_minus_ad = @b * @c - @a * @d
    @_inverse = new Matrix(
      @d / ad_minus_bc,
      @b / bc_minus_ad,
      @c / bc_minus_ad,
      @a / ad_minus_bc,
      (@d * @e - @c * @f) / bc_minus_ad
      (@b * @e - @a * @f) / ad_minus_bc
    )

  fromLocal: ([x, y]) ->
    [
      @a * x + @c * y + @e
      @b * x + @d * y + @f
    ]

  toLocal: ([x, y]) ->
    @inverse().fromLocal([x, y])

  origin: ->
    [@e, @f]


  toSVG: ->
    "matrix(#{@m.join(" ")})"

  canvasSetTransform: (ctx) ->
    ctx.setTransform(@a, @b, @c, @d, @e, @f)

  canvasTransform: (ctx) ->
    ctx.transform(@a, @b, @c, @d, @e, @f)


Matrix.naturalConstruct = (x, y, sx, sy, rotate) ->
  c = Math.cos(rotate)
  s = Math.sin(rotate)
  return new Matrix(
    c * sx
    s * sx
    -s * sy
    c * sy
    x
    y
  )
