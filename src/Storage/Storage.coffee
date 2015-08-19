module.exports = Storage = {}


Storage.Serializer = require "./Serializer"

Storage.saveFile = (text, name, type) ->
  dummyLink = document.createElement("a")
  file = new Blob([text], {type})
  dummyLink.href = URL.createObjectURL(file)
  dummyLink.download = name
  dummyLink.click()
