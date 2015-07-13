R = require "./View/R"
Model = require "./Model/Model"



# For debugging
Apparatus = window.Apparatus = {}
Apparatus.Dataflow = require "./Dataflow/Dataflow"
Apparatus.Model = Model
Apparatus.R = R
Apparatus.Util = require "./Util/Util"





project = new Model.Project()
project.viewedElement = Model.Rectangle




render = ->
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

