R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "RightPanel",
  contextTypes:
    editor: Model.Editor

  toggleRightPanel: ->
    # TODO find a cleaner mechanism to store the toggled state
    @context.editor.layout.rightPanelWidth = if @context.editor.layout.rightPanelWidth == 10 then 400 else 10

    # TODO I don't know a clean way to communicate the resizeEvent so for now I'm triggering a "resize" event to do the trick...
    resize = new Event "resize"
    window.dispatchEvent resize

  render: ->
    R.div { 
        className: "RightPanel"
        style: {
          width: @context.editor.layout.rightPanelWidth
        }
      },
      R.div { 
        className: "RightResize"
        onClick: @toggleRightPanel
      }
      R.Outline {}
      R.Inspector {}

