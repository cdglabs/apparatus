_ = require "underscore"
Model = require "./Model"
Dataflow = require "../Dataflow/Dataflow"
Util = require "../Util/Util"
NodeVisitor = require "../Util/NodeVisitor"


module.exports = class Project
  constructor: ->
    initialElement = @createNewElement()

    @editingElement = initialElement
    @selectedParticularElement = null

    @createPanelElements = [
      Model.Rectangle
      Model.Circle
      Model.Text
      Model.Image
      initialElement
    ]

    propsToMemoize = [
      "controlledAttributes"
      "implicitlyControlledAttributes"
      "controllableAttributes"
      "editingElementNodesById"
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

  rootNodes: ->
    rootNodes = @createPanelElements.slice()
    for name, obj of Model
      if Model.Node.isPrototypeOf(obj)
        rootNodes.push(obj)
    return rootNodes

  findUnnecessaryNodes: ->
    # These nodes are necessary per se.
    rootNodes = @rootNodes()

    unnecessaryNodes = []

    # If a node is necessary, its master is necessary and its children are
    # necessary. Its parent and its variants are not necessarily necessary.
    necessaryNodeVisitor = new NodeVisitor
      linksToFollow: {master: yes, variants: no, parent: no, children: yes}
    necessaryNodeVisitor.visit(rootNode) for rootNode in rootNodes

    connectedNodeVisitor = new NodeVisitor
      linksToFollow: {master: yes, variants: yes, parent: yes, children: yes}
      onVisit: (node) ->
        if !necessaryNodeVisitor.hasVisited(node)
          unnecessaryNodes.push(node)
    connectedNodeVisitor.visit(rootNode) for rootNode in rootNodes

    connectedNodeVisitor.finish()
    necessaryNodeVisitor.finish()

    return unnecessaryNodes


  # ===========================================================================
  # Memoized attribute sets
  # ===========================================================================

  controlledAttributes: ->
    return @selectedParticularElement?.element.controlledAttributes() ? []

  implicitlyControlledAttributes: ->
    return @selectedParticularElement?.element.implicitlyControlledAttributes() ? []

  controllableAttributes: ->
    return @selectedParticularElement?.element.controllableAttributes() ? []

  editingElementNodesById: ->
    nodesById = {}

    nodeVisitor = new NodeVisitor
      linksToFollow: {master: yes, variants: no, parent: no, children: yes}
      onVisit: (node) ->
        nodesById[Util.getId(node)] = node
    nodeVisitor.visit(@editingElement)
    nodeVisitor.finish()

    return nodesById


  # ===========================================================================
  # Compatibility fixes
  # ===========================================================================

  # Whenever a project is loaded from a saved copy,
  # `performIdempotentCompatibilityFixes` is run on it. If you want to make a
  # breaking change to the format of a project, but you can come up with a way
  # to update old projects, put it in here.
  performIdempotentCompatibilityFixes: ->
    @switchExpressionsToUseNodeIdsAsReferences()

  # See https://github.com/cdglabs/apparatus/pull/63
  switchExpressionsToUseNodeIdsAsReferences: ->
    rootNodes = @rootNodes()

    nodeVisitor = new NodeVisitor
      linksToFollow: {master: yes, variants: no, parent: no, children: yes}
      onVisit: (node) ->
        if node.isVariantOf(Model.Attribute) and node.isNovel()
          exprString = node.exprString
          references = node.references()

          newExprString = exprString
          newReferences = {}

          _.each references, (reference, key) ->
            id = Util.getId(reference)
            newExprString = newExprString.replace(new RegExp(key, "g"), id)
            newReferences[id] = reference

          node.setExpression(newExprString, newReferences)

    nodeVisitor.visit(rootNode) for rootNode in rootNodes
    nodeVisitor.finish()
