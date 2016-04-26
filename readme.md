# Apparatus

Apparatus is a hybrid graphics editor / programming environment for creating interactive diagrams.

An interactive diagram can be an effective way to communicate a mental model, because it can convey a way of seeing a problem or system. Currently, to create an interactive diagram one must write code to procedurally draw the diagram and respond appropriately to user input. Writing this code can take hours or days. Apparatus aims to reduce the time to create an interactive diagram from hours to minutes.

The Apparatus editor runs in the browser. You can play with it, see examples, and watch tutorials on the [Apparatus homepage](http://aprt.us).

![Apparatus Usage](http://aprt.us/assets/usage.png)


# Building the project

First run `npm install`, which will install all the dependencies for building Apparatus.

Then run `npm run dev`, which starts up a webpack dev server. This will watch for changes to `src/` and `style/`, compile them automatically, and host the resulting app at http://localhost:8080. Even better, http://localhost:8080/webpack-dev-server will automatically reload your browser when files change and keep you informed of the build status along the way.

To build a static version of Apparatus, run `npm run build`. This will compile the coffeescript files in `src/` into `dist/apparatus.js` and the stylus files in `style/` into `dist/apparatus.css`. Now you can open `index.html` in a browser to run the Apparatus editor.

You can run `npm run test` to run all the tests in `test/`.

See all of the commands you can run in the `scripts` section of `package.json`.

## Compiling the icon font

If you add an icon to the icon font (by putting an svg into the `icons` folder), you'll need to rebuild the icon font (the stuff in `dist/font` including `dist/font/icons.css`).

To do this you'll need to install [fontcustom](https://github.com/FontCustom/fontcustom/). Then in the terminal run:

    fontcustom compile


# Directory structure

* `dist` contains the built javascript and CSS that `npm run build` will build.
* `doc` contains some additional pictures and documentation on Apparatus.
* `icons` contains SVG icons which are built into an icon font using [fontcustom](https://github.com/FontCustom/fontcustom/).
* `src` contains the coffeescript source code for Apparatus.
* `style` contains the stylus source code which is built into CSS.
* `test` contains some tests for the model code. Run the tests with `npm run test`.
* `thirdparty` contains some third party javascript libraries that are used by Apparatus.
