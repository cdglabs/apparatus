module.exports = Storage = {}


Storage.Serializer = require "./Serializer"

Storage.saveFile = (text, name, type) ->
  dummyLink = document.createElement("a")
  file = new Blob([text], {type})
  dummyLink.href = URL.createObjectURL(file)
  dummyLink.download = name
  dummyLink.click()

Storage.loadFile = (callback) ->
  dummyInput = document.createElement("input")
  dummyInput.setAttribute("type", "file")
  dummyInput.addEventListener "change", (changeEvent) ->
    files = dummyInput.files
    file = files[0]
    return unless file
    reader = new FileReader()
    reader.onload = ->
      callback(reader.result)
    reader.readAsText(file)
  dummyInput.click()
