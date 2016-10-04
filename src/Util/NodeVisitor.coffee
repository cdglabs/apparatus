# TODO: what about hatching?

module.exports = class NodeVisitor
  constructor: ({@onVisit, @linksToFollow}) ->
    @visitedNodes = []

  visit: (node) ->
    if @hasVisited(node)
      return

    node.__visitors.push(this)
    @visitedNodes.push(node)

    @onVisit(node) if @onVisit

    if @linksToFollow.master
      master = node.master()
      @visit(master) if master
    if @linksToFollow.variants and node.isHatched()
      @visit(variant) for variant in node.variants()
    if @linksToFollow.parent
      parent = node.parent()
      @visit(parent) if parent
    if @linksToFollow.children and node.isHatched()
      @visit(child) for child in node.children()
    return

  hasVisited: (node) ->
    node.__visitors = [] if !node.hasOwnProperty('__visitors')
    return node.__visitors.indexOf(this) != -1

  finish: ->
    for node in @visitedNodes
      visitors = node.__visitors
      index = visitors.indexOf(this)
      if index == -1 then throw 'visitor list inconsistency'
      visitors.splice(index, 1)
    return
