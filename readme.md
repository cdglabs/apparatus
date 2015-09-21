# Apparatus

Apparatus is a hybrid graphics editor / programming environment for creating interactive diagrams.

An interactive diagram can be an effective way to communicate a mental model, because it can convey a way of seeing a problem or system. Currently, to create an interactive diagram one must write code to procedurally draw the diagram and respond appropriately to user input. Writing this code can take hours or days. Apparatus aims to reduce the time to create an interactive diagram from hours to minutes.

TODO insert links to:

* Examples
* Tutorials
* Technical description (e.g. FPW paper)




# Building the project

First run `npm install` which will install all the dependencies for building Apparatus.

Then you can run `npm run build` which will compile the coffeescript files in `src/` into `dist/apparatus.js` and the stylus files in `style/` into `dist/apparatus.css`. Now you can open `index.html` in a browser to run the Apparatus editor.

For development, you can also run `npm run dev` which will set up a watcher for changes to `src/` and `style/` and also a livereload server. To use livereload, you will need to install an [extension](http://livereload.com/extensions/) for your browser.

You can run `npm run test` to run all the tests in `test/`.

See all of the commands you can run in the `scripts` section of `package.json`.

## Compiling the icon font

If you add an icon to the icon font (by putting an svg into the `icons` folder), you'll need to rebuild the icon font (the stuff in `dist/font` including `dist/font/icons.css`).

To do this you'll need to install [fontcustom](http://fontcustom.com/). Then in the terminal run:

    fontcustom compile



# Summary of Modules

## Dataflow

## Model




Editor and UI State

State Persistence

jsEvaluate

Matrix

util

View

