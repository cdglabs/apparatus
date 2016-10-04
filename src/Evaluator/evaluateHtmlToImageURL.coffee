HtmlToSvg = require "../Util/HtmlToSvg"


module.exports = htmlToImageURL = (html, width, height) ->
  svg = HtmlToSvg.convertHtmlToSvgSimple(
    """<body xmlns="http://www.w3.org/1999/xhtml">#{html}</body>""",
    width, height
  )
  url = "data:image/svg+xml;charset=utf-8," + encodeURIComponent(svg);
  return url
