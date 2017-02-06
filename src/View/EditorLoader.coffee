R = require "./R"
Model = require "../Model/Model"


# EditorLoader is a little shell around Editor which displays "loading" /
# "error" messages when the editor first loads. (The most technical reason for
# its existence is that Editor wants a project in its childContextTypes, but a
# project doesn't exist until it is loaded.)
R.create "EditorLoader",
  propTypes:
    editor: Model.Editor

  render: ->
    {editor} = @props
    if editor.project
      R.Editor {editor},
    else if editor.initialLoadError
      R.div {style: {margin: 20}},
        R.div {style: {margin: "20px 0", fontSize: "200%"}},
          "Problem loading diagram"
        R.div {style: {margin: "20px 0"}},
          editor.initialLoadError.toString()
        R.button {onClick: -> editor.performLocalInitialLoad()},
          "Start editor anyway"
    else
      R.div {style: {margin: 20, fontSize: "200%"}}, "Loading diagram..."
