`View` contains all the code for rendering the Apparatus editor in the browser. It is built on [React](http://facebook.github.io/react/).

The root of this directory is `R.coffee`. It's named `R` because it's used so often that View would be tedious to write, and because it makes available the React API that we use. It also implements some syntactic sugar that I found to be useful in writing React components in Coffeescript.

The top-level component is `Editor`. Editor is passed in (via props) the Project to render (see Model.Project). We make use of React context, which as yet is not officially documented. We use context to hold the project, since many sub-components need to reference it, and also to hold *managers* which are used to coordinate *across* components. `DragManager` coordinates dragging operations (e.g. from the create panel into the canvas), `HoverManager` coordinates hovers (e.g. so that when the mouse hovers an element it is highlighted in all the components).

The `Generic` directory contains React components that do not depend on any logic from Apparatus and could conceivably be reused in other projects.
