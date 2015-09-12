_ = require "underscore"
Model = require "./Model"
Dataflow = require "../Dataflow/Dataflow"


module.exports = class Project
  constructor: ->
    initialElement = @createNewElement()

    @editingElement = initialElement
    @selectedParticularElement = null

    @createPanelElements = [
      Model.Rectangle
      Model.Circle
      Model.Text
      initialElement
    ]

    propsToMemoize = [
      "controlledAttributes"
      "implicitlyControlledAttributes"
      "controllableAttributes"
    ]
    for prop in propsToMemoize
      this[prop] = Dataflow.memoize(this[prop].bind(this))


  # ===========================================================================
  # Selection
  # ===========================================================================

  setEditing: (element) ->
    @editingElement = element
    @selectedParticularElement = null

  select: (particularElement) ->
    if !particularElement
      @selectedParticularElement = null
      return
    @selectedParticularElement = particularElement
    @_expandToElement(particularElement.element)

  _expandToElement: (element) ->
    while element = element.parent()
      element.expanded = true


  # ===========================================================================
  # Actions
  # ===========================================================================

  createNewElement: ->
    element = Model.Group.createVariant()
    element.expanded = true
    return element

  removeSelectedElement: ->
    return unless @selectedParticularElement
    selectedElement = @selectedParticularElement.element
    parent = selectedElement.parent()
    return unless parent
    parent.removeChild(selectedElement)
    @select(null)

  groupSelectedElement: ->
    return unless @selectedParticularElement
    selectedElement = @selectedParticularElement.element
    parent = selectedElement.parent()
    return unless parent
    group = Model.Group.createVariant()
    group.expanded = true
    parent.replaceChildWith(selectedElement, group)
    group.addChild(selectedElement)
    @select(new Model.ParticularElement(group))

  duplicateSelectedElement: ->
    # This implementation is a little kooky in that it creates a master that
    # is not in createPanelElements. This leads to weirdness with showing
    # novel attributes in the right sidebar.
    return unless @selectedParticularElement
    selectedElement = @selectedParticularElement.element
    parent = selectedElement.parent()
    return unless parent
    firstClone = selectedElement.createVariant()
    secondClone = selectedElement.createVariant()
    parent.replaceChildWith(selectedElement, firstClone)
    index = parent.children().indexOf(firstClone)
    parent.addChild(secondClone, index+1)
    @select(new Model.ParticularElement(secondClone))

  createSymbolFromSelectedElement: ->
    return unless @selectedParticularElement
    selectedElement = @selectedParticularElement.element
    parent = selectedElement.parent()
    return unless parent
    master = selectedElement
    variant = selectedElement.createVariant()
    parent.replaceChildWith(selectedElement, variant)
    @select(new Model.ParticularElement(variant))
    # Insert master into createPanelElements.
    index = @createPanelElements.indexOf(@editingElement)
    @createPanelElements.splice(index, 0, master)


  # ===========================================================================
  # Memoized attribute sets
  # ===========================================================================

  controlledAttributes: ->
    return @selectedParticularElement?.element.controlledAttributes() ? []

  implicitlyControlledAttributes: ->
    return @selectedParticularElement?.element.implicitlyControlledAttributes() ? []

  controllableAttributes: ->
    return @selectedParticularElement?.element.controllableAttributes() ? []
