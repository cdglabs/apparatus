module.exports = class ImageCache
  constructor: ->
    @_images = {}
    @_callbacksToRun = {}

  getSync: (url) ->
    @_images[url]  # will be undefined if url is not saved

  get: (url, callback) ->
    # Either the image is cached...
    if @_images[url]
      callback(@_images[url])

    # Or it is already being loaded...
    else if @_callbacksToRun[url]
      @_callbacksToRun[url].push(callback)

    # Or it's totally new...
    else
      @_callbacksToRun[url] = [callback]

      image = new Image()
      if not url.startsWith("data:")
        # (Safari doesn't like .crossOrigin when loading "data:" URLs)
        image.crossOrigin = "Anonymous"
      image.addEventListener "load", =>
        @_images[url] = image
        anyCallback(image) for anyCallback in @_callbacksToRun[url]
        delete @_callbacksToRun[url]
      image.src = url
