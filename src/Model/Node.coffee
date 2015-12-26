###

# Introduction

The *node* is the *foundational abstraction* for managing the *scene graph* of
diagrams as well as the *inheritance hierarchy*.

The scene graph is managed through parent and children relationships. This is
very much like the DOM: every node can have 0 or 1 parent and the `addChild`
and `removeChild` methods ensure that all the parent/children pointers point
at the right thing.

Nodes can have properties in addition to children. These are managed simply as
javascript properties on the node objects.

Inheritance is handled a little differently. To reduce confusion, we use a
different nomenclature than class-instance or prototype-??. We call a node a
*master* and say that it can have *variants*. You can create a new variant
simply by calling the `createVariant` method.

The master-variant relationship is similar to the prototype relationship.
Indeed we use javascript's built-in prototype tree, so if A is the master of
B, then B.__proto__ == A. Thus properties inherit as in prototypal inheritance.

Children, however, inherit a little differently. Specifically, the entire
scene graph *structure* is also inherited.

So when you create a variant of a node, you also implicitly create
corresponding variants of each of the node's children and so on recursively.
That is, you create a deep clone of the node in such a way that every created
node has as its master the analogous node in the original tree. So if I have a
node A with children B and C and I create a variant of A called A', then A'
will automatically have as its children B' and C' which are variants of B and
C respectively.

Additionally, every variant node also has a pointer to its *head*. The head is
the root of the cloned tree. So if I have Node A with child Node B and I
create a variant of A to make A' with child B', then both A' and B' will have
as their head A'. We keep track of this in order to find *analogous* nodes
from one tree to another.


# Overriding

In addition to a variant overriding properties of its master, as in normal
prototypal inheritance, a variant can also override the children structure of
its master. That is, you can add and remove children from the variant. These
changes *will not* propagate back up to the master. However, changes made to a
master (adding and removing children) *will* propagate down to its variants.


# Lazy Implementation

We use a lazy implementation in order to support infinite recursion. An
example of recursion would be Node A has as a child Node A' which is a clone
of A. You can follow the children down as far as you want to go (by calling
Node.children() recursively), but the system won't crash by trying to create
an infinite data structure.

We achieve this with a "thunk" strategy. When Nodes are initially created they
are "eggs". It is only when they are asked about their children that they
"hatch" and instantiate their children. (And their children are instantiated
as eggs, of course.)

We want consumers of this API to never know that the implementation is lazy.
It should appear that you can just access Node.children(), etc. and always get
back the correct Node(s), as if we had infinite memory. Thus we need to hatch
the appropriate Node(s) when certain calls are made--basically whenever we go
"down" the tree.

###

_ = require "underscore"


module.exports = Node = {
  label: "Node"

  constructor: ->
    @_master = null
    @_variants = []

    @_parent = null
    @_children = []

    @_head = null

    @_isHatched = false


  # ===========================================================================
  # Accessors
  # ===========================================================================

  master: -> @_master

  variants: ->
    # If we just returned @_variants this would expose the lazy
    # implementation because the answer depends on what's hatched. For
    # example, if A is the parent of B and A' is a variant of A but is not
    # hatched, then B.variants() will not return the corresponding B'
    # because it doesn't exist yet (because A' is not hatched).

    # But by hatching all my parent's variants, we guarantee that all of my
    # variants must exist, and therefore must be in @_variants.
    if parent = @parent()
      parentVariants = parent.variants()
      for parentVariant in parentVariants
        parentVariant._hatch()

    return @_variants

  parent: ->
    @_parent

  children: ->
    @_hatch()
    return @_children

  head: -> @_head


  # ===========================================================================
  # Hatching (required to work with children)
  # ===========================================================================

  _hatch: ->
    return if @_isHatched

    # Make sure my master is hatched.
    @_master?._hatch()

    @_isHatched = true

    if @_master?
      for masterChild in @_master.children()
        myChild = masterChild._createVariantWithHead(@_head)
        @addChild(myChild)


  # ===========================================================================
  # Working with children
  # ===========================================================================

  addChild: (childToAdd, insertionIndex=Infinity) ->
    # Will add childToAdd to children such that it appears in children() at
    # insertionIndex.

    @_hatch()

    existingParent = childToAdd.parent()

    # Remove child from its existing parent.
    if existingParent
      existingParent.removeChild(childToAdd)

    # Add child
    @_children.splice(insertionIndex, 0, childToAdd)
    childToAdd._parent = this

    # Add a corresponding child to each of my hatched variants.
    for variant in @_variants
      # Don't bother if the variant isn't hatched. It will create a variant of
      # the child once it hatches.
      continue unless variant._isHatched

      head = variant.head()

      # First look to see if the variant child already exists.
      correspondingChild = childToAdd.findVariantWithHead(head)

      if !correspondingChild
        # If the corresponding child does not exist, create it by creating a
        # variant of childToAdd.
        correspondingChild = childToAdd._createVariantWithHead(head)

      variant.addChild(correspondingChild, insertionIndex)

  removeChild: (childToRemove) ->
    @_hatch()

    # Remove the child
    insertionIndex = @_children.indexOf(childToRemove)
    if insertionIndex == -1
      throw "Cannot remove a child that doesn't exist"

    @_children.splice(insertionIndex, 1)
    childToRemove._parent = null

    # Remove the corresponding child in each of my hatched variants.
    for variant in @_variants
      # Don't bother if the variant isn't hatched. It will take on the
      # appropriate children when it hatches.
      continue unless variant._isHatched

      head = variant.head()

      correspondingChild = childToRemove.findVariantWithHead(head)
      if correspondingChild?.parent() == variant
        variant.removeChild(correspondingChild)


  # ===========================================================================
  # Creating Variants
  # ===========================================================================

  _createVariantWithHead: (head=null, spec) ->
    variant = Object.create(this)
    _.extend(variant, spec) if spec?
    variant.constructor()

    if !head?
      head = variant

    variant._head = head
    variant._master = this
    @_variants.push(variant)

    return variant

  createVariant: (spec) ->
    return @_createVariantWithHead(null, spec)


  # ===========================================================================
  # Finding variants.
  # ===========================================================================

  findVariantWithHead: (head) ->
    return _.find @variants(), (variant) ->
      variant.head() == head


  # ===========================================================================
  # Helpers
  # ===========================================================================

  isVariantOf: (grandMaster) ->
    return grandMaster == this or grandMaster.isPrototypeOf(this)

  isAncestorOf: (grandChild) ->
    if this == grandChild
      return true
    if parent = grandChild.parent()
      return @isAncestorOf(parent)
    return false

  addChildren: (children) ->
    @addChild(child) for child in children

  childrenOfType: (type) ->
    _.filter @children(), (child) -> child.isVariantOf(type)

  childOfType: (type) ->
    _.find @children(), (child) -> child.isVariantOf(type)

  depth: ->
    return 0 if !@parent()
    return 1 + @parent().depth()

  replaceChildWith: (childToReplace, replacementNode) ->
    index = @children().indexOf(childToReplace)
    @removeChild(childToReplace)
    @addChild(replacementNode, index)


  # ===========================================================================
  # Dev tools
  # ===========================================================================

  devLabel: ->
    return @devLabel || @label || "[NO LABEL]"

  # Returns a chain of masters.
  masterLineage: (labelsOnly=false) ->
    @lineage("master", labelsOnly)

  # Returns a chain by following these rules:
  #   * If you have a parent, it comes next.
  #   * Otherwise, if you have a master, it comes next.
  #   * Otherwise, we're done.
  parentThenMasterLineage: (labelsOnly=false)->
    @lineage(["parent", "master"], labelsOnly)

  # Returns a chain by following these rules:
  #   * If you have a head (other than yourself), it comes next.
  #   * Otherwise, if you have a master, it comes next.
  #   * Otherwise, we're done.
  headThenMasterLineage:  (labelsOnly=false)->
    @lineage(["head", "master"], labelsOnly)

  # Returns a chain by following links in a provided order of precedence. Step
  # type annotations are provided if `precedence` is an array, rather than a
  # single type.
  lineage: (precedence, labelsOnly=false) ->
    entry = if labelsOnly then @devLabel() else this
    precedenceIsArray = _.isArray(precedence)
    precedenceArray = if precedenceIsArray then precedence else [precedence]
    for stepType in precedenceArray
      possibleNextStep = @["_" + stepType]
      if possibleNextStep and (possibleNextStep != this)
        nextStepType = stepType
        lineage = possibleNextStep.lineage(precedence, labelsOnly)
        break
    if not nextStepType
      nextStepType = "end"
      lineage = []
    lineage.unshift(if precedenceIsArray then [entry, nextStepType] else entry)
    return lineage
}

Node.constructor()
