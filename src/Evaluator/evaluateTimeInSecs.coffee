timeout = null
periodMillis = 33

module.exports = now = () ->
  theNow = Date.now()

  if not timeout
    timeout = window.setTimeout(
      () ->
        timeout = null
        Apparatus.refresh()  # HACK: calling Apparatus seems funky here.
      , periodMillis)

  return theNow / 1000
