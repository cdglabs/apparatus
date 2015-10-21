R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "RightPanel",
  contextTypes:
    editor: Model.Editor

  render: ->
    R.div { 
        className: "RightPanel"
        style: {
          width: @context.editor.layout.rightPanelWidth
        }
      },
      R.Outline {}
      R.Inspector {}

