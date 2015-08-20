_ = require "underscore"
R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "Outline",
  contextTypes:
    project: Model.Project

  render: ->
    project = @context.project
    element = project.editingElement
    R.div {className: "Outline"},
      R.div {className: "Header"}, "Outline"
      R.div {className: "Scroller"},
        R.OutlineTree {element}


R.create "OutlineTree",
  propTypes:
    element: Model.Element

  contextTypes:
    dragManager: R.DragManager

  render: ->
    {element} = @props
    {dragManager} = @context

    isExpanded = element.expanded
    drag = dragManager.drag
    isBeingDragged = drag?.type == "outlineReorder" and
      drag.consummated and
      drag.element == element

    outlineTree = R.div {className: "OutlineTree"},
      R.OutlineItem {element}
      if isExpanded
        R.OutlineChildren {element}

    if isBeingDragged
      R.div {},
        R.div {className: "OutlineDragging", style: {
          left: drag.x
          top: drag.y
          width: drag.width
        }},
          outlineTree
        R.div {className: "OutlinePlaceholder", style: {height: drag.height}}
    else
      outlineTree


R.create "OutlineItem",
  propTypes:
    element: Model.Element

  contextTypes:
    project: Model.Project
    hoverManager: R.HoverManager
    dragManager: R.DragManager

  render: ->
    project = @context.project
    element = @props.element
    hoverManager = @context.hoverManager

    isSelected = project.selectedParticularElement?.element == element
    isHovered = hoverManager.hoveredParticularElement?.element == element
    isActiveController = hoverManager.controllerParticularElement?.element == element
    isController = element.isController()
    isExpanded = element.expanded

    R.div {
      className: R.cx {
        OutlineItem: true
        isSelected, isHovered, isActiveController, isController
      }
      onMouseDown: @_onMouseDown
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
      R.NovelAttributesList {element}

  _setLabelValue: (newValue) ->
    @props.element.label = newValue

  _onMouseDown: (mouseDownEvent) ->
    target = mouseDownEvent.target
    return if Util.closest(target, ".Interactive")
    mouseDownEvent.preventDefault()
    Util.clearTextFocus()
    @_select()
    @_startDragToReorder(mouseDownEvent)

  _onMouseEnter: ->
    dragManager = @context.dragManager
    hoverManager = @context.hoverManager
    element = @props.element

    return if dragManager.drag?
    particularElement = new Model.ParticularElement(element)
    hoverManager.hoveredParticularElement = particularElement

  _onMouseLeave: ->
    dragManager = @context.dragManager
    hoverManager = @context.hoverManager

    return if dragManager.drag?
    hoverManager.hoveredParticularElement = null

  _onClickTriangle: ->
    element = @props.element
    element.expanded = !element.expanded
    return

  _select: ->
    {element} = @props
    {project} = @context
    particularElement = new Model.ParticularElement(element)
    project.select(particularElement)

  _startDragToReorder: (mouseDownEvent) ->
    {element} = @props
    {dragManager} = @context

    el = @getDOMNode()
    outlineTreeEl = Util.closest(el, ".OutlineTree")
    outlineEl = Util.closest(el, ".Outline")
    rect = outlineTreeEl.getBoundingClientRect()

    offsetX = mouseDownEvent.clientX - rect.left
    offsetY = mouseDownEvent.clientY - rect.top

    width = rect.width
    height = rect.height

    dragManager.start mouseDownEvent,
      type: "outlineReorder"
      element: element
      outlineEl: outlineEl
      width: width
      height: height
      onMove: (mouseMoveEvent) =>
        dragManager.drag.x = mouseMoveEvent.clientX - offsetX
        dragManager.drag.y = mouseMoveEvent.clientY - offsetY
        # TODO

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
        R.OutlineTree {element: childElement, key: Util.getId(childElement)}







# TODO: Move to another file.

R.create "NovelAttributesList",
  propTypes:
    element: Model.Element

  contextTypes:
    project: Model.Project

  render: ->
    {element} = @props
    {project} = @context

    R.div {className: "AttributesList"},
      for attribute in element.attributes()
        if attribute.isNovel()
          R.AttributeRow {attribute}
      if element == project.editingElement
        R.div {className: "AddVariableRow"},
          R.button {className: "AddButton Interactive", onClick: @_addVariable}

  _addVariable: ->
    {element} = @props
    element.addVariable()




