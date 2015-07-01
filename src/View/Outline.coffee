R = require "./R"
Model = require "../Model/Model"


R.create "Outline",
  propTypes:
    element: Model.Element

  render: ->
    element = @props.element
    R.div {className: "Outline"},
      R.div {className: "Header"}, "Outline"
      R.div {className: "Scroller"},
        R.OutlineTree {element}

R.create "OutlineTree",
  propTypes:
    element: Model.Element

  render: ->
    element = @props.element
    isExpanded = element.expanded or true
    isBeingDragged = false

    # dragPayload = State.UI.dragPayload
    # isBeingDragged = dragPayload?.type == "outlineReorder" and dragPayload.consummated and dragPayload.element == @element

    outlineTree = R.div {className: "OutlineTree"},
      R.OutlineItem {element}
      if isExpanded
        R.OutlineChildren {element}

    if isBeingDragged
      R.div {},
        # R.div {className: "OutlineDragging", style: {
        #   left: mouse.x - dragPayload.offsetX
        #   top: mouse.y - dragPayload.offsetY
        #   width: dragPayload.width
        # }},
        #   outlineTree
        # R.div {className: "OutlinePlaceholder", style: {height: dragPayload.height}}
    else
      outlineTree

R.create "OutlineItem",
  propTypes:
    element: Model.Element

  render: ->
    element = @props.element
    isSelected = false
    isHovered = false
    isController = false
    isExpanded = element.expanded

    R.div {
      className: R.cx {
        OutlineItem: true
        isSelected, isHovered, isController
      }
      onMouseDown: @_select
      onMouseEnter: @_onMouseEnter
      onMouseLeave: @_onMouseLeave
    },
      R.div {className: "ElementRow"},
        R.div {className: "ElementRowDisclosure"},
          R.div {
            className: R.cx {
              DisclosureTriangle: true
              Interactive: true
              isExpanded
            }
            onClick: @_onClickTriangle,
          }
        R.div {className: "ElementRowLabel"},
          R.EditableText {
            className: "EditableTextInline Interactive"
            value: element.label
            setValue: @_setLabelValue
          }
      # R.PartialAttributesList {element: @element}

  _setLabelValue: (newValue) ->
    @props.element.label = newValue

  _onMouseEnter: ->
    # return if State.UI.dragPayload
    # State.Editor.setHovered(@element)

  _onMouseLeave: ->
    # return if State.UI.dragPayload
    # State.Editor.setHovered(null)

  _onClickTriangle: ->
    # @element.setExpanded(!@element.isExpanded())
    # return

  _select: (mouseDownEvent) ->
    # target = mouseDownEvent.target
    # return if util.dom.closest(target, ".Interactive")
    # util.mouseDownPreventDefault(mouseDownEvent)
    # State.Editor.setSelected(@element)

    # @_startDragToReorder(mouseDownEvent)

  _startDragToReorder: (mouseDownEvent) ->
    # el = @getDOMNode()
    # outlineTreeEl = util.dom.closest(el, ".OutlineTree")
    # outlineEl = util.dom.closest(el, ".Outline")
    # rect = outlineTreeEl.getBoundingClientRect()

    # offsetX = mouseDownEvent.clientX - rect.left
    # offsetY = mouseDownEvent.clientY - rect.top

    # width = rect.width
    # height = rect.height

    # payload = {
    #   type: "outlineReorder"
    #   element: @element
    #   offsetX, offsetY, width, height
    #   outlineEl
    # }

    # State.UI.startDrag mouseDownEvent,
    #   # TODO: Figure out how sticky drags want to work, e.g. have a handle
    #   # that does the drag, or sticky drag if the item is selected.
    #   sticky: false
    #   payload: payload
    #   onMove: =>
    #     dropSpot = @_findDropSpot()
    #     if dropSpot?
    #       @_reorderItem(dropSpot)

  _findDropSpot: ->
    # dragPayload = State.UI.dragPayload
    # {outlineEl} = dragPayload

    # dragPosition = [
    #   mouse.x - dragPayload.offsetX
    #   mouse.y - dragPayload.offsetY
    # ]

    # # Hide OutlinePlaceholder for the purpose of this calculation.
    # outlinePlaceholderEl = outlineEl.querySelector(".OutlinePlaceholder")
    # outlinePlaceholderEl?.style.display = "none"

    # # Keep track of the best drop spot.
    # bestDropSpot = {
    #   quadrance: 40 * 40 # Threshold to be considered.
    # }
    # checkFit = (droppedPosition, outlineChildrenEl, beforeOutlineTreeEl) =>
    #   quadrance = util.quadrance(dragPosition, droppedPosition)
    #   if quadrance < bestDropSpot.quadrance
    #     bestDropSpot = {quadrance, outlineChildrenEl, beforeOutlineTreeEl}

    # # All the places within which we could drop.
    # outlineChildrenEls = outlineEl.querySelectorAll(".OutlineChildren")

    # for outlineChildrenEl in outlineChildrenEls
    #   # Don't try to insert it into itself!
    #   continue if util.dom.closest(outlineChildrenEl, ".OutlineDragging")

    #   # Check fit before each existing child.
    #   childEls = _.filter(outlineChildrenEl.childNodes, (el) -> util.dom.matches(el, ".OutlineTree"))
    #   for childEl in childEls
    #     rect = childEl.getBoundingClientRect()
    #     droppedPosition = [rect.left, rect.top]
    #     checkFit(droppedPosition, outlineChildrenEl, childEl)

    #   # Check fit after the last child.
    #   rect = outlineChildrenEl.getBoundingClientRect()
    #   droppedPosition = [rect.left, rect.bottom]
    #   checkFit(droppedPosition, outlineChildrenEl, null)

    # # Clean up by unhiding OutlinePlaceholder
    # outlinePlaceholderEl?.style.display = ""

    # if bestDropSpot.outlineChildrenEl
    #   return bestDropSpot
    # else
    #   return null

  _reorderItem: (dropSpot) ->
    # dragPayload = State.UI.dragPayload
    # {outlineChildrenEl, beforeOutlineTreeEl} = dropSpot
    # {element} = dragPayload

    # parentElement = outlineChildrenEl.dataFor.element

    # if beforeOutlineTreeEl
    #   beforeElement = beforeOutlineTreeEl.dataFor.element
    #   parentElement.removeChild(element)
    #   index = parentElement.children().indexOf(beforeElement)
    #   parentElement.addChild(element, index)
    # else
    #   parentElement.addChild(element)







R.create "OutlineChildren",
  propTypes:
    element: Model.Element

  render: ->
    element = @props.element

    R.div {className: "OutlineChildren"},
      for childElement in element.childElements()
        R.OutlineTree {element: childElement}



# R.create "PartialAttributesList",
#   propTypes:
#     element: Model.Element

#   render: ->
#     # Show only variables.
#     visibleAttributes = @element.attributes()

#     R.div {className: "AttributesList"},
#       for attribute in visibleAttributes
#         R.AttributeRow {attribute}
#       if @element == State.Editor.topSelected()
#         R.div {className: "AddVariableRow"},
#           R.button {className: "AddButton", onClick: @_addVariable}

#   _addVariable: ->
#     @element.addVariable()





# R.create "Inspector",
#   propTypes:
#     element: Model.Element

#   render: ->
#     R.div {className: "Inspector"},
#       R.div {className: "Header"},
#         @element.label
#       R.div {className: "Scroller"},
#         R.FullAttributesList {element: @element}





# R.create "FullAttributesList",
#   propTypes:
#     element: Model.Element

#   render: ->
#     R.div {className: "InspectorList"},
#       R.div {className: "ComponentSection"},
#         R.div {className: "ComponentSectionTitle"},
#           R.span {},
#             "Variables"
#         R.div {className: "ComponentSectionContent"},
#           for attribute in @element.attributes()
#             R.AttributeRow {attribute}
#         R.div {className: "AddVariableRow"},
#           R.button {className: "AddButton", onClick: @_addVariable}


#       for component in @element.components()
#         R.ComponentSection {component}

#   _addVariable: ->
#     @element.addVariable()






# R.create "ComponentSection",
#   propTypes:
#     component: Model.Component

#   render: ->
#     R.div {className: "ComponentSection"},
#       R.div {className: "ComponentSectionTitle"},
#         R.span,
#           @component.label
#       R.div {className: "ComponentSectionContent"},
#         for attribute in @component.attributes()
#           R.AttributeRow {attribute}








