`Graphic` contains classes which represent shapes or marks that are ready to be drawn to the screen. Each Graphic class has a `render` and a `hitDetect` method which enable rendering and interactivity.

The structure of Graphic roughly follows the structure of Model. Thus Elements and Components in Model have a graphicClass property which references the class that they should become when you call `Element.graphic`.

During rendering, an Element generates a Graphic by calling its `graphic` or `allGraphics` method. In this process, all of the dataflow and spreads are computed, resulting in Graphic objects whose properties are primitives (numbers, strings, matrices, etc.) and are thus ready to be rendered.

Additionally, Graphics are annotated with a `particularElement` property which points back at the Element and SpreadEnv that generated it. This is used during hit detection to trace back from the rendered canvas to select or manipulate part of the model.
