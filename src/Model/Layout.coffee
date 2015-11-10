
module.exports = class Layout
  constructor: ->  
    @rightPanelWidth = 400
    @fullScreen = false

    @_rightPanelMin = 100
    @_rightPanelMax = 600

  # applies the constraints to the new right panel width
  constraintRightPanelWidth: (newWidth) ->
    @rightPanelWidth = Math.min(@_rightPanelMax, Math.max(@_rightPanelMin, newWidth))
    @_refreshLayout()

  toggleFullScreen: ->
    @fullScreen = !@fullScreen
    @_refreshLayout()

  _refreshLayout: ->
    # Changing the layout will deform the canvas
    # This is a workaround by triggering "resize" event so that the Canvas will update itself
    resize = new Event "resize"
    window.dispatchEvent resize
