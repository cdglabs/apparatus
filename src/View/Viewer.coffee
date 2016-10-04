R = require "./R"
Model = require "../Model/Model"


R.create "Viewer",
  propTypes:
    project: Model.Project

  childContextTypes:
    project: Model.Project

  getChildContext: ->
    project: @props.project

  render: ->
    R.MouseManagersWrapper {},
      R.BareViewerCanvas {
        element: @props.project.editingElement
      }
