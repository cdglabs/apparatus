_ = require "underscore"

require "codemirror/addon/hint/show-hint"
require "codemirror/mode/javascript/javascript"
CodeMirror = require "codemirror"


R = require "./R"
Model = require "../Model/Model"
Dataflow = require "../Dataflow/Dataflow"
Util = require "../Util/Util"


R.create "Expression",
  propTypes:
    attribute: Model.Attribute

  render: ->
    attribute = @props.attribute

    R.div {className: "Expression"},
      R.ExpressionCode {attribute}
      R.ExpressionValue {attribute}


R.create "ExpressionCode",
  propTypes:
    attribute: Model.Attribute

  contextTypes:
    project: Model.Project
    dragManager: R.DragManager
    hoverManager: R.HoverManager
    # Note: we need to include all the context variables to pass down to
    # ContextWrapper (for CodeMirror marks).

  render: ->
    attribute = @props.attribute

    R.div {
      className: "ExpressionCode Interactive"
      onMouseUp: @_onMouseUp
    }

  componentDidMount: ->
    el = @getDOMNode()

    # We annotate the dom node to support the "click an attribute to
    # transclude it" feature.
    el.component = this

    @mirror = CodeMirror(el, {
      mode: "javascript"

      # Needed for auto-expanding height to work properly.
      viewportMargin: Infinity

      # Use tabs to indent.
      smartIndent: true
      indentUnit: 2
      tabSize: 2
      indentWithTabs: true

      # # Extra key handlers
      # extraKeys: @extraKeys
    })

    @mirror.on("change", @_onChange)
    @mirror.on("mousedown", @_onMirrorMouseDown)
    @componentDidUpdate()

  componentDidUpdate: ->
    @_updateMirrorFromAttribute()

  _onChange: ->
    @_updateAttributeFromMirror()
    if @mirror.hasFocus()
      @_showAutocomplete()

  _onMirrorMouseDown: (mirror, mouseDownEvent) ->
    el = mouseDownEvent.target
    if Util.matches(el, ".cm-number")
      mouseDownEvent.preventDefault()
      @_startNumberScrub(mouseDownEvent)

  _onMouseUp: (mouseUpEvent) ->
    {attribute} = @props
    {dragManager} = @context
    if dragManager.drag?.type == "transcludeAttribute"
      @transcludeAttribute(dragManager.drag.attribute)


  # ===========================================================================
  # Updating (from both directions)
  # ===========================================================================

  _updateMirrorFromAttribute: ->
    attribute = @props.attribute
    value = attribute.exprString ? ""
    if @mirror.getValue() != value
      @mirror.setValue(value)
    @_markAttributeTokens()

  _updateAttributeFromMirror: ->
    attribute = @props.attribute
    newExprString = @mirror.getValue()
    if attribute.exprString != newExprString
      # We clean up references to get rid of attribute references which no
      # longer appear in exprString.
      oldReferences = attribute.references()
      newReferences = {}
      for own referenceKey, referenceNode of oldReferences
        isUsed = (newExprString.indexOf(referenceKey) != -1)
        if isUsed
          newReferences[referenceKey] = referenceNode
      attribute.setExpression(newExprString, newReferences)


  # ===========================================================================
  # Transcluding an attribute (creating a reference)
  # ===========================================================================

  transcludeAttribute: (referenceAttribute) ->
    if @mirror.hasFocus()
      @_replaceSelectionWithReference(referenceAttribute)
    else
      @_replaceAllWithReference(referenceAttribute)

  _replaceSelectionWithReference: (referenceAttribute) ->
    {attribute} = @props
    references = attribute.references()
    referenceKey = Util.generateId()
    references[referenceKey] = referenceAttribute
    exprString = attribute.exprString
    attribute.setExpression(exprString, references)
    @mirror.replaceSelection(referenceKey)

  _replaceAllWithReference: (referenceAttribute) ->
    {attribute} = @props
    references = {}
    referenceKey = Util.generateId()
    references[referenceKey] = referenceAttribute
    exprString = referenceKey
    attribute.setExpression(exprString, references)


  # ===========================================================================
  # Displaying reference tokens
  # ===========================================================================

  # References to other Attributes within an expression get displayed as
  # tokens. This is implemented using CodeMirror's marker API.
  #
  # http://codemirror.net/doc/manual.html#api_marker

  _markAttributeTokens: ->
    attribute = @props.attribute
    value = @mirror.getValue()

    marks = []
    for own referenceKey, referenceAttribute of attribute.references()
      for startChar in Util.stringMatchIndices(value, referenceKey)
        endChar = startChar + referenceKey.length
        from = Util.charToLineCh(value, startChar)
        to = Util.charToLineCh(value, endChar)
        marks.push {
          from
          to
          render: ->
            R.AttributeToken {
              attribute: referenceAttribute
              # contextAttribute: attribute
            }
        }

    @_updateMarks(marks)

  _updateMarks: (marks) ->
    @_existingMarks ?= []
    updatedMarks = []
    existingMarksToRemove = []

    for existingMark in @_existingMarks
      keepExistingMark = false
      range = existingMark.find()

      if range
        for mark in marks
          corresponds = (range.from.line == mark.from.line and
            range.from.ch == mark.from.ch and
            range.to.line == mark.to.line and
            range.to.ch == mark.to.ch)
          if corresponds
            # Update the existing mark.
            @_renderMark(mark, existingMark.el)
            # Let CodeMirror know that the mark might have changed size.
            existingMark.changed()
            updatedMarks.push(mark)
            keepExistingMark = true

      unless keepExistingMark
        existingMarksToRemove.push(existingMark)

    for existingMarkToRemove in existingMarksToRemove
      existingMarkToRemove.clear()
      @_existingMarks = _.without(@_existingMarks, existingMarkToRemove)

    for mark in marks
      unless mark in updatedMarks
        # Add a new mark
        el = document.createElement("span")
        @_renderMark(mark, el)
        newMark = @mirror.markText(mark.from, mark.to, {
          replacedWith: el
        })
        newMark.el = el
        @_existingMarks.push(newMark)

  _renderMark: (mark, el) ->
    wrappedReactElement = R.ContextWrapper {
      context: @context
      childRender: mark.render
    }
    React.render(wrappedReactElement, el)


  # ===========================================================================
  # Autocomplete
  # ===========================================================================

  _showAutocomplete: ->
    # TODO

    # @mirror.showHint
    #   hint: @_hint
    #   completeSingle: false
    #   # Uncomment below to play with styling in browser inspector.
    #   # closeOnUnfocus: false

  _hint: (mirror) ->
    cursor = mirror.getCursor()
    token = mirror.getTokenAt(cursor)

    if token.type == "variable" and token.string.indexOf("$$$") == -1
      from = CodeMirror.Pos(cursor.line, token.start)
      to = CodeMirror.Pos(cursor.line, cursor.ch)
      letters = token.string.toLowerCase()

      # Find possible completions
      completions = []

      attributeLabelEls = document.querySelectorAll(".AttributeLabel")
      attributes = _.map attributeLabelEls, (attributeLabelEl) ->
        attributeLabelEl.dataFor.node

      attributes = _.unique(attributes)

      for attribute in attributes
        # Need closure on attribute.
        do (attribute) =>
          label = attribute.label
          completionLetters = label.toLowerCase()
          isMatch = _.every letters, (letter) ->
            completionLetters.indexOf(letter) != -1

          if isMatch
            completions.push
              text: label
              displayText: label
              hint: =>
                mirror.setSelection(from, to)
                @_replaceSelectionWithAttributeToken(attribute)

      # Create new Attribute completion.
      completions.push
        text: token.string
        displayText: "Create Variable: "+token.string
        hint: =>
          # Create a new Variable
          attribute = Model.Attribute.createVariant()
          attribute.label = token.string
          attribute.setExpression("0.00")
          State.Editor.topSelected().addChild(attribute)

          mirror.setSelection(from, to)
          @_replaceSelectionWithAttributeToken(attribute)

      return {
        list: completions
        from, to
      }
    else
      return null


  # ===========================================================================
  # Number Scrubbing
  # ===========================================================================

  _startNumberScrub: (mouseDownEvent) ->
    {start, end} = @_getTokenPositionFromCursor(mouseDownEvent)
    @mirror.focus()
    @mirror.setSelection(start, end)
    @_startScrubbingSelection(mouseDownEvent)

  _getTokenPositionFromCursor: (mouseDownEvent) ->
    position = @mirror.coordsChar({left: mouseDownEvent.clientX, top: mouseDownEvent.clientY})
    # Make sure it's really on the right character.
    if @mirror.cursorCoords(position).left < mouseDownEvent.clientX
      position.ch++
    token = @mirror.getTokenAt(position)

    # start and end keep track of which span of text we'll be replacing.
    start = {line: position.line, ch: token.start}
    end   = {line: position.line, ch: token.end}

    # Bring in negative sign if necessary.
    if start.ch > 0
      earlyStart = {line: start.line, ch: start.ch - 1}
      if @mirror.getRange(earlyStart, start) == "-"
        # TODO: Need to check that it's not subtraction (e.g. 22-30)
        start = earlyStart

    return {start, end}

  _startScrubbingSelection: (mouseDownEvent) ->
    dragManager = @context.dragManager

    originalValue = +@mirror.getSelection()
    precision = Util.precision(@mirror.getSelection())

    startX = mouseDownEvent.clientX

    dragManager.start mouseDownEvent,
      cursor: "ew-resize"
      onMove: (moveEvent) =>
        dx = moveEvent.clientX - startX
        dx = dx / 3
        delta = dx * Math.pow(10, -precision)
        newValue = originalValue + delta
        # if key.command
        #   newValue = Util.roundToPrecision(newValue, precision - 1)
        newValue = Util.toPrecision(newValue, precision)
        @mirror.replaceSelection(""+newValue, "around")






  # _onMouseUp: (e) ->
  #   return unless State.UI.dragPayload?.type == "transcludeAttribute"

  #   targetNode = State.UI.dragPayload.attribute

  #   mirror = @refs.CodeMirror.mirror
  #   if mirror.hasFocus()
  #     @_replaceSelectionWithAttributeToken(targetNode)
  #   else
  #     @_replaceAllWithAttributeToken(targetNode)

  # _replaceSelectionWithAttributeToken: (attribute) ->
  #   mirror = @refs.CodeMirror.mirror
  #   references = @attribute.references()

  #   referenceKey = null
  #   for own key, referenceAttribute of references
  #     if referenceAttribute == attribute
  #       referenceKey = key
  #       break
  #   referenceKey ?= @attribute.generateReferenceKey()

  #   references[referenceKey] = attribute

  #   # Note: this is a little convoluted in that it ends up calling
  #   # @attribute.setExpression here...
  #   exprString = @attribute.exprString
  #   @attribute.setExpression(exprString, references)
  #   # ... and then again here:
  #   mirror.replaceSelection(referenceKey)

  # _replaceAllWithAttributeToken: (attribute) ->
  #   mirror = @refs.CodeMirror.mirror
  #   referenceKey = @attribute.generateReferenceKey()
  #   exprString = referenceKey
  #   references = {}
  #   references[referenceKey] = attribute
  #   @attribute.setExpression(exprString, references)



















R.create "ExpressionValue",
  propTypes:
    attribute: Model.Attribute
  render: ->
    attribute = @props.attribute
    if attribute.isTrivial()
      R.span {}
    else
      value = attribute.value()
      R.div {className: "ExpressionValue"},
        R.Value {value: value}



R.create "Value",
  propTypes:
    value: "any"
  render: ->
    value = @props.value
    R.span {className: "Value"},
      if value instanceof Error
        "(Error)"
      else if _.isFunction(value)
        "(Function)"
      else if value instanceof Dataflow.Spread
        # TODO: Make this better
        "(Spread) " + JSON.stringify(value.items)
      else if _.isNumber(value)
        Util.toMaxPrecision(value, 3)
      else
        JSON.stringify(value)



R.create "SpreadValue",
  propTypes:
    spread: "any"
  maxSpreadItems: 5
  render: ->
    R.span {className: "SpreadValue"},
      for index in [0...Math.min(@spread.length, @maxSpreadItems)]
        value = @spread.take(index)
        R.span {className: "SpreadValueItem"},
          R.Value {value: value}
      if @spread.length > @maxSpreadItems
        "..."








