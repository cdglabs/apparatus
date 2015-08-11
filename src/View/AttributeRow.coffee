R = require "./R"
Model = require "../Model/Model"


R.create "AttributeRow",
  propTypes:
    attribute: Model.Attribute

  render: ->
    attribute = @props.attribute

    R.div {className: R.cx {
      AttributeRow: true
    }},
      R.div {className: "AttributeRowControl"},
        R.div {
          className: R.cx {
            AttributeControl: true
            Interactive: true
            # Controllable: @_isControllable()
            # Controlled: @_isControlled()
            # ImplicitlyControlled: @_isImplicityControlled()
          }
          # onClick: @_toggleControl
        }
      R.div {className: "AttributeRowLabel"},
        R.AttributeLabel {attribute}
      R.div {className: "AttributeRowExpression"},
        R.Expression {attribute}

  # _isControlled: ->
  #   controlledAttributes = State.Editor.getSelectedElement().getControlledAttributes()
  #   return _.contains(controlledAttributes, @attribute)

  # _isImplicityControlled: ->
  #   implicitlyControlledAttributes = State.Editor.getSelectedElement().getImplicitlyControlledAttributes()
  #   return _.contains(implicitlyControlledAttributes, @attribute)

  # _isControllable: ->
  #   controllableAttributes = State.Editor.getSelectedElement().getControllableAttributes()
  #   return _.contains(controllableAttributes, @attribute)

  # _toggleControl: ->
  #   if @_isControlled()
  #     State.Editor.getSelectedElement().removeControlledAttribute(@attribute)
  #   else
  #     State.Editor.getSelectedElement().addControlledAttribute(@attribute)


R.create "AttributeLabel",
  propTypes:
    attribute: Model.Attribute

  contextTypes:
    dragManager: R.DragManager
    hoverManager: R.HoverManager

  render: ->
    {attribute} = @props
    {hoverManager} = @context

    R.div {
      className: R.cx {
        AttributeLabel: true
        Interactive: true
        isHovered: hoverManager.hoveredAttribute == attribute
        # Variable: @node.parent().isVariantOf(Element)
      }
      onMouseDown: @_onMouseDown
      onMouseOver: @_onMouseOver
      onMouseOut:  @_onMouseOut
    },
      R.EditableText {
        className: "EditableTextInline Interactive"
        value: attribute.label
        setValue: (newValue) ->
          attribute.label = newValue
      }

  _onMouseDown: (e) ->
    # return if util.dom.closest(e.target, ".EditableTextInline")

    # # Note: we do a normal preventDefault instead of
    # # util.mouseDownPreventDefault because we don't want to lose text focus
    # # (for transcluding an attribute to a certain location in code).
    # e.preventDefault()

    # payload = {
    #   type: "transcludeAttribute"
    #   attribute: @node
    # }

    # State.UI.startDrag e,
    #   payload: payload
    #   cursor: util.cursor("grabbing")
    #   sticky: true

  _onMouseOver: (e) ->
    {attribute} = @props
    {dragManager, hoverManager} = @context
    return if dragManager.drag?
    hoverManager.hoveredAttribute = attribute

  _onMouseOut: (e) ->
    {dragManager, hoverManager} = @context
    return if dragManager.drag?
    hoverManager.hoveredAttribute = null


# R.create "AttributeToken",
#   propTypes:
#     attribute: Model.Attribute
#     contextAttribute: {optional: Model.Attribute}

#   render: ->
#     R.span {
#       className: R.cx {
#         ReferenceToken: true
#         Hovered: State.UI.isAttributeHovered(@attribute)
#       }
#       onMouseEnter: @_onMouseEnter
#       onMouseLeave: @_onMouseLeave
#     },
#       @_label()
#       # R.Value {value: @attribute.evaluate()}

#   # TODO: This helper should be moved somewhere else (Node?)
#   _parentElement: (node) ->
#     return null if !node?
#     return node if node.isVariantOf(Model.Element)
#     return @_parentElement(node.parent())

#   _label: ->
#     if @contextAttribute
#       contextElement = @_parentElement(@contextAttribute)
#       element = @_parentElement(@attribute)
#       isSameContext = element.isAncestorOf(contextElement)
#       if !isSameContext
#         return @attribute.parent().label + "’s " + @attribute.label
#     return @attribute.label

#   _onMouseEnter: ->
#     return if State.UI.dragPayload
#     State.UI.setAttributeHovered(@attribute)

#   _onMouseLeave: ->
#     return if State.UI.dragPayload
#     State.UI.setAttributeHovered(null)













