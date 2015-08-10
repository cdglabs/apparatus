`Model` contains all of the classes and prototype `Node`s upon which the Apparatus model is built. That is, this code determines the *internal representation* that the Apparatus editor uses to represent the interactive diagram being constructed.

Much of this structure is built via prototypical inheritance on `Node`s. A `Node` is an object that can spawn variants (via the `createVariant` method). Variants inherit properties from their *master* because they are linked to their master via the javascript prototype chain. Additionally, variants inherit *children* from their master. See `Node.coffee` for more details.

Node thus provides the unique inheritance power of Apparatus. However, because tracking children in Nodes incurs some overhead costs, parts of the model which do not need this power use more traditional javascript classes.

TODO: A screenshot of the Editor with labels pointing out which parts of the view correspond to which part of the model.

TODO: An inheritance diagram showing all the Nodes (e.g. Node, Element, Attribute, etc.)

TODO: A diagram showing the children hierarchy of a simple example.
