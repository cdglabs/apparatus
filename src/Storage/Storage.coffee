module.exports = Storage = {}


Storage.Serializer = require "./Serializer"

# `text` should be a string of text that should be written to the file, `name`
# `the file name (e.g. `"hello.json"`), and `type` the content type (e.g.
# ``"application/json"`).
Storage.saveFile = (text, name, type) ->
  dummyLink = document.createElement("a")
  file = new Blob([text], {type})
  dummyLink.href = URL.createObjectURL(file)
  dummyLink.download = name
  dummyLink.click()

# This will pop open the file open dialog box. If a file is loaded
# successfully, callback will be called with a string that is the text of the
# file.
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
