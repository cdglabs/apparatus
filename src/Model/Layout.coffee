
module.exports = class Layout
  constructor: ->  
    @rightPanelWidth = 400
    @_rightPanelMin = 100
    @_rightPanelMax = 600
    @fullScreen = false

  resizeRightPanel: (xDelta) ->
    @rightPanelWidth -= xDelta
    @rightPanelWidth = Math.min(@_rightPanelMax, Math.max(@_rightPanelMin, @rightPanelWidth))
    @_refreshLayout()

  toggleFullScreen: ->
    @fullScreen = !@fullScreen
    @_refreshLayout()

  _refreshLayout: ->
    # Changing the layout will deform the canvas
    # This is a workaround by triggering "resize" event so that the Canvas will update itself
    resize = new Event "resize"
    window.dispatchEvent resize

