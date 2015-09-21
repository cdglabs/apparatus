_ = require "underscore"
R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "AttributeRow",
  propTypes:
    attribute: Model.Attribute

  contextTypes:
    project: Model.Project
    hoverManager: R.HoverManager

  render: ->
    attribute = @props.attribute

    R.div {className: R.cx {
      AttributeRow: true
      isInherited: !attribute.isNovel()
      isWrapped: @_isWrapped()
      isGoingToChange: @_isGoingToChange()
    }},
      R.div {className: "AttributeRowControl"},
        R.div {
          className: R.cx {
            AttributeControl: true
            Interactive: true
            isControllable: @_isControllable()
            isControlled: @_isControlled()
            isImplicitlyControlled: @_isImplicityControlled()
          }
          onClick: @_toggleControl
        }
      R.div {className: "AttributeRowLabel"},
        R.AttributeLabel {attribute}
      R.div {className: "AttributeRowExpression"},
        R.Expression {attribute}

  _isWrapped: ->
    {attribute} = @props
    return attribute.exprString.indexOf("\n") != -1

  _isGoingToChange: ->
    {attribute} = @props
    {hoverManager} = @context
    return _.contains(hoverManager.attributesToChange, attribute)

  _selectedElement: ->
    {project} = @context
    return selectedElement = project.selectedParticularElement?.element

  _isControlled: ->
    return _.contains(@context.project.controlledAttributes(), @props.attribute)

  _isImplicityControlled: ->
    return _.contains(@context.project.implicitlyControlledAttributes(), @props.attribute)

  _isControllable: ->
    return _.contains(@context.project.controllableAttributes(), @props.attribute)

  _toggleControl: ->
    {attribute} = @props
    {project} = @context
    selectedElement = project.selectedParticularElement?.element
    return unless selectedElement
    if @_isControlled()
      selectedElement.removeControlledAttribute(attribute)
    else
      selectedElement.addControlledAttribute(attribute)


R.create "AttributeLabel",
  propTypes:
    attribute: Model.Attribute

  contextTypes:
    dragManager: R.DragManager
    hoverManager: R.HoverManager

  mixins: [R.AnnotateMixin]

  render: ->
    {attribute} = @props
    {hoverManager} = @context

    R.div {
      className: R.cx {
        AttributeLabel: true
        Interactive: true
        isHovered: hoverManager.hoveredAttribute == attribute
        isGoingToChange: _.contains(hoverManager.attributesToChange, attribute)
      }
      onMouseDown: @_onMouseDown
      onMouseEnter: @_onMouseEnter
      onMouseLeave: @_onMouseLeave
    },
      R.EditableText {
        className: "EditableTextInline Interactive"
        value: attribute.label
        setValue: (newValue) ->
          attribute.label = newValue
      }

  annotation: ->
    # For autocomplete to find all the attributes on the screen.
    {attribute: @props.attribute}

  _onMouseDown: (mouseDownEvent) ->
    return if Util.closest(mouseDownEvent.target, ".EditableTextInline")

    {attribute} = @props
    {dragManager, hoverManager} = @context
    mouseDownEvent.preventDefault()
    dragManager.start mouseDownEvent,
      type: "transcludeAttribute"
      attribute: attribute
      x: mouseDownEvent.clientX
      y: mouseDownEvent.clientY
      onMove: (mouseMoveEvent) ->
        dragManager.drag.x = mouseMoveEvent.clientX
        dragManager.drag.y = mouseMoveEvent.clientY
      onDrop: ->
        hoverManager.hoveredAttribute = null
      # cursor
      onCancel: =>
        @_transcludeIntoFocusedExpression()

  _transcludeIntoFocusedExpression: ->
    {attribute} = @props
    focusedCodeMirrorEl = document.querySelector(".CodeMirror-focused")
    return unless focusedCodeMirrorEl
    expressionCodeEl = Util.closest(focusedCodeMirrorEl, ".ExpressionCode")
    expressionCode = expressionCodeEl.annotation.component
    expressionCode.transcludeAttribute(attribute)

  _onMouseEnter: (e) ->
    {attribute} = @props
    {dragManager, hoverManager} = @context
    return if dragManager.drag?
    hoverManager.hoveredAttribute = attribute

  _onMouseLeave: (e) ->
    {dragManager, hoverManager} = @context
    return if dragManager.drag?
    hoverManager.hoveredAttribute = null


R.create "AttributeToken",
  propTypes:
    attribute: Model.Attribute
    contextElement: "any" # TODO: should be Model.Element or null

  contextTypes:
    dragManager: R.DragManager
    hoverManager: R.HoverManager

  render: ->
    {attribute} = @props
    {hoverManager} = @context

    R.span {
      className: R.cx {
        ReferenceToken: true
        isHovered: hoverManager.hoveredAttribute == attribute
        isGoingToChange: _.contains(hoverManager.attributesToChange, attribute)
      }
      onMouseEnter: @_onMouseEnter
      onMouseLeave: @_onMouseLeave
    },
      @_label()

  _label: ->
    {attribute, contextElement} = @props
    parentElement = attribute.parentElement()
    if contextElement
      isSameContext = parentElement.isAncestorOf(contextElement)
    else
      isSameContext = false
    if isSameContext
      return attribute.label
    else
      return "#{parentElement.label}’s #{attribute.label}"

  _onMouseEnter: (e) ->
    {attribute} = @props
    {dragManager, hoverManager} = @context
    return if dragManager.drag?
    hoverManager.hoveredAttribute = attribute

  _onMouseLeave: (e) ->
    {dragManager, hoverManager} = @context
    return if dragManager.drag?
    hoverManager.hoveredAttribute = null













