R = require "./R"
Model = require "../Model/Model"


R.create "Menubar",
  contextTypes:
    editor: Model.Editor

  render: ->
    R.div {className: "Menubar"},
      R.div {className: "MenubarItem", onClick: @_new}, "New"
      R.div {className: "MenubarItem", onClick: @_load}, "Load"
      R.div {className: "MenubarItem", onClick: @_save}, "Save"

      R.div {className: "MenubarSeparator"}

      R.div {className: "MenubarItem"}, "Undo"
      R.div {className: "MenubarItem"}, "Redo"

      R.div {className: "MenubarSeparator"}

      R.div {className: "MenubarItem"}, "Delete"
      R.div {className: "MenubarItem"}, "Group"
      R.div {className: "MenubarItem"}, "Duplicate"
      R.div {className: "MenubarItem"}, "Create Symbol"

  _new: ->
    {editor} = @context
    editor.createNewProject()

  _load: ->

  _save: ->
    {editor} = @context
    editor.saveToFile()
