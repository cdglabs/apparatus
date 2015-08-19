R = require "./R"
Model = require "../Model/Model"


R.create "Menubar",
  contextTypes:
    editor: Model.Editor
    project: Model.Project

  render: ->
    {project} = @context
    isSelection = project.selectedParticularElement?

    R.div {className: "Menubar"},
      R.MenubarItem {title: "New", isDisabled: false, fn: @_new}
      R.MenubarItem {title: "Load", isDisabled: false, fn: @_load}
      R.MenubarItem {title: "Save", isDisabled: false, fn: @_save}

      R.div {className: "MenubarSeparator"}

      R.MenubarItem {title: "Undo", isDisabled: true, fn: @_todo}
      R.MenubarItem {title: "Redo", isDisabled: true, fn: @_todo}

      R.div {className: "MenubarSeparator"}

      R.MenubarItem {title: "Delete", isDisabled: !isSelection, fn: @_todo}
      R.MenubarItem {title: "Group", isDisabled: !isSelection, fn: @_todo}
      R.MenubarItem {title: "Duplicate", isDisabled: !isSelection, fn: @_todo}
      R.MenubarItem {title: "Create Symbol", isDisabled: !isSelection, fn: @_todo}

  _new: ->
    {editor} = @context
    editor.createNewProject()

  _load: ->

  _save: ->
    {editor} = @context
    editor.saveToFile()

  _todo: ->


R.create "MenubarItem",
  propTypes:
    title: String
    isDisabled: Boolean
    fn: Function

  render: ->
    {title, isDisabled, fn} = @props
    R.div {
      className: R.cx {
        MenubarItem: true
        isDisabled: isDisabled
      }
      onClick: @_activate
    }, title

  _activate: ->
    {isDisabled, fn} = @props
    return if isDisabled
    fn()
