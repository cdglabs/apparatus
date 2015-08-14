_ = require "underscore"
R = require "./View/R"
Model = require "./Model/Model"
Dataflow = require "./Dataflow/Dataflow"
Storage = require "./Storage/Storage"
Util = require "./Util/Util"


# For debugging
Apparatus = window.Apparatus = {}
Apparatus.Dataflow = Dataflow
Apparatus.Model = Model
Apparatus.Storage = Storage
Apparatus.R = R
Apparatus.Util = Util




# Initialize Storage built-in objects. TODO: Maybe move this into another
# file?
do ->
  builtInObjects = []
  for own name, object of Model
    if _.isFunction(object)
      object = object.prototype
    Util.assignId(object, name)
    builtInObjects.push(object)
  Storage.Serializer.loadBuiltInObjects(builtInObjects)





project = new Model.Project()

# For debugging
Apparatus.project = project




render = ->
  Dataflow.run ->
    R.render(R.Editor({project}), document.body)

render()


willRefreshNextFrame = false
refresh = ->
  return if willRefreshNextFrame
  willRefreshNextFrame = true
  requestAnimationFrame ->
    render()
    # if shouldCheckpoint and !State.UI.dragPayload?
    #   State.checkpoint()
    #   shouldCheckpoint = false
    willRefreshNextFrame = false

refreshEventNames = [
  "mousedown"
  "mousemove"
  "mouseup"
  "keydown"
  "keyup"
  "scroll"
  "change"
  "wheel"
  "mousewheel"
]

for eventName in refreshEventNames
  window.addEventListener(eventName, refresh)

