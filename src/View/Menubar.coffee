key = require "keymaster"
R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "Menubar",
  contextTypes:
    editor: Model.Editor
    project: Model.Project

  render: ->
    {editor, project} = @context
    isSelection = project.selectedParticularElement?

    if editor.layout.fullScreen
      return null

    R.div { className: "Menubar" },
      R.MenubarItem {title: "New", isDisabled: false, fn: @_new}
      R.MenubarItem {title: "Load", isDisabled: false, fn: @_load}
      if editor.experimental
        R.MenubarItem {title: "Merge", isDisabled: false, fn: @_merge}
      R.MenubarItem {title: "Save", isDisabled: false, fn: @_save}
      if editor.experimental
        R.MenubarItem {title: "Share", isDisabled: false, fn: @_share}

      R.div {className: "MenubarSeparator"}

      R.MenubarItem {title: "Undo", isDisabled: !editor.isUndoable(), fn: @_undo}
      R.MenubarItem {title: "Redo", isDisabled: !editor.isRedoable(), fn: @_redo}

      R.div {className: "MenubarSeparator"}

      R.MenubarItem {title: "Delete", isDisabled: !isSelection, fn: @_removeSelectedElement}
      R.MenubarItem {title: "Group", isDisabled: !isSelection, fn: @_groupSelectedElement}
      # R.MenubarItem {title: "Duplicate", isDisabled: !isSelection, fn: @_duplicateSelectedElement}
      R.MenubarItem {title: "Create Symbol", isDisabled: !isSelection, fn: @_createSymbolFromSelectedElement}

      if editor.experimental
        [
          R.div {className: "MenubarSeparator"}
          R.div {className: "MenubarSeparator"}

          R.div {style: {color: "red"}}, "Experimental mode is on"
        ]

  componentDidMount: ->
    key "command+o, ctrl+o", (e) =>
      e.preventDefault()
      @_load()

    key "command+s, ctrl+s", (e) =>
      e.preventDefault()
      @_save()

    key "command+z, ctrl+z", (e) =>
      e.preventDefault()
      @_undo()

    key "command+shift+z, ctrl+y", (e) =>
      e.preventDefault()
      @_redo()

    key "backspace", (e) =>
      # We need to check that we're not editing text, since in this case
      # pressing the backspace key should backspace a letter.
      return if Util.textFocus()
      e.preventDefault()
      @_removeSelectedElement()

    key "command+g, ctrl+g", (e) =>
      e.preventDefault()
      @_groupSelectedElement()

  _new: ->
    {editor} = @context
    editor.createNewProject()

  _load: ->
    {editor} = @context
    editor.loadFromFile()

  _merge: ->
    {editor} = @context
    editor.mergeFromFile()

  _save: ->
    {editor} = @context
    editor.saveToFile()

  _share: ->
    {editor} = @context
    editor.saveToFirebase()

  _undo: ->
    {editor} = @context
    editor.undo()

  _redo: ->
    {editor} = @context
    editor.redo()

  _todo: ->

  _removeSelectedElement: ->
    {project} = @context
    project.removeSelectedElement()

  _groupSelectedElement: ->
    {project} = @context
    project.groupSelectedElement()

  _duplicateSelectedElement: ->
    {project} = @context
    project.duplicateSelectedElement()

  _createSymbolFromSelectedElement: ->
    {project} = @context
    project.createSymbolFromSelectedElement()


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
