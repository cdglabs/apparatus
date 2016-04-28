_ = require "underscore"
R = require "./R"
Model = require "../Model/Model"
Util = require "../Util/Util"


R.create "Outline",
  contextTypes:
    project: Model.Project

  render: ->
    {project} = @context
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

  mixins: [R.AnnotateMixin]

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

  annotation: ->
    # Used for drag reording.
    {element: @props.element}


R.create "OutlineChildren",
  propTypes:
    element: Model.Element

  mixins: [R.AnnotateMixin]

  render: ->
    {element} = @props
    R.div {className: "OutlineChildren"},
      for childElement in element.childElements()
        R.OutlineTree {element: childElement, key: Util.getId(childElement)}

  annotation: ->
    # Used for drag reording.
    {element: @props.element}


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


  # ===========================================================================
  # Event Logic
  # ===========================================================================

  _onMouseDown: (mouseDownEvent) ->
    target = mouseDownEvent.target
    return if Util.closest(target, ".Interactive")
    mouseDownEvent.preventDefault()
    Util.clearTextFocus()
    @_select()
    @_startDragToReorder(mouseDownEvent)

  _onMouseEnter: ->
    {element} = @props
    {dragManager, hoverManager} = @context
    return if dragManager.drag?
    particularElement = new Model.ParticularElement(element)
    hoverManager.hoveredParticularElement = particularElement

  _onMouseLeave: ->
    {dragManager, hoverManager} = @context
    return if dragManager.drag?
    hoverManager.hoveredParticularElement = null


  # ===========================================================================
  # Actions
  # ===========================================================================

  _setLabelValue: (newValue) ->
    @props.element.label = newValue

  _onClickTriangle: ->
    {element} = @props
    element.expanded = !element.expanded
    return

  _select: ->
    {element} = @props
    {project} = @context
    particularElement = new Model.ParticularElement(element)
    project.select(particularElement)


  # ===========================================================================
  # Drag Reorder
  # ===========================================================================

  _startDragToReorder: (mouseDownEvent) ->
    {element} = @props
    {dragManager} = @context

    el = R.findDOMNode(@)
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
        dropSpot = @_findDropSpot(dragManager.drag)
        if dropSpot
          @_reorderItem(dropSpot)

  # _findDropSpot returns a dropSpot object consisting of outlineChildrenEl
  # (where to insert) and beforeOutlineTreeEl (where to insert after, if null
  # then insert at the end). If nothing is close enough, it will return null.
  _findDropSpot: (drag) ->
    {x, y, outlineEl} = drag
    dragPosition = [x, y]

    # Temporarily hide OutlinePlaceholder for the purpose of this calculation.
    outlinePlaceholderEl = outlineEl.querySelector(".OutlinePlaceholder")
    outlinePlaceholderEl?.style.display = "none"

    # Keep track of the best drop spot.
    bestDropSpot = {
      quadrance: 40 * 40 # Threshold to be considered close enough to drop.
    }
    checkFit = (droppedPosition, outlineChildrenEl, beforeOutlineTreeEl) =>
      quadrance = Util.quadrance(dragPosition, droppedPosition)
      if quadrance < bestDropSpot.quadrance
        bestDropSpot = {quadrance, outlineChildrenEl, beforeOutlineTreeEl}

    # All the places within which we could drop.
    outlineChildrenEls = outlineEl.querySelectorAll(".OutlineChildren")

    for outlineChildrenEl in outlineChildrenEls
      # Don't try to insert it into itself!
      continue if Util.closest(outlineChildrenEl, ".OutlineDragging")

      # Check fit before each existing child.
      childEls = _.filter(outlineChildrenEl.childNodes, (el) -> Util.matches(el, ".OutlineTree"))
      for childEl in childEls
        rect = childEl.getBoundingClientRect()
        droppedPosition = [rect.left, rect.top]
        checkFit(droppedPosition, outlineChildrenEl, childEl)

      # Check fit after the last child.
      rect = outlineChildrenEl.getBoundingClientRect()
      droppedPosition = [rect.left, rect.bottom]
      checkFit(droppedPosition, outlineChildrenEl, null)

    # Clean up by unhiding OutlinePlaceholder
    outlinePlaceholderEl?.style.display = ""

    if bestDropSpot.outlineChildrenEl
      return bestDropSpot
    else
      return null

  # _reorderItem will move my element to a dropSpot. dropSpot should be an
  # object with outlineChildrenEl (where to insert) and beforeOutlineTreeEl
  # (where to insert after, if null then insert at the end).
  _reorderItem: (dropSpot) ->
    {element} = @props
    {outlineChildrenEl, beforeOutlineTreeEl} = dropSpot

    parentElement = outlineChildrenEl.annotation.element
    if beforeOutlineTreeEl
      beforeElement = beforeOutlineTreeEl.annotation.element
      if parentElement.children().indexOf(element) != -1
        parentElement.removeChild(element)
      index = parentElement.children().indexOf(beforeElement)
      parentElement.addChild(element, index)
    else
      parentElement.addChild(element)
