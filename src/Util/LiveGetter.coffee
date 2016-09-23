request = require 'superagent'
xml2js = require 'xml2js'


# Adding XML-parsing support to superagent...
parseXML = (res, fn) ->
  # xml2js is fake-async, so we just use the callback to set the closure vals
  # and use them immediately.
  vals = undefined
  xml2js.parseString(res, {async: false}, (err, res) => vals = {err, res})
  if vals.err
    throw vals.err
  return vals.res
request.parse['application/xml'] = parseXML
request.parse['text/xml'] = parseXML


# LiveGetter manages a bunch of HTTP requests which will want to be refreshed on
# a regular interval. A user of LiveGetter calls `liveGetter.get(myURL,
# myPeriod)` to 1. get the most recent results of a request to `myURL`, 2. spawn
# a new request, if the last one was longer than `myPeriod` ago, and 3. keep a
# timer running so that even if nothing else is keeping Apparatus awake,
# Apparatus will still refresh to make more calls to `get`.
#
# LiveGetter is wired into the rest of Apparatus, in the sense that it calls
# `Apparatus.refresh()` when results come back (or the timer runs out).
# TODO: Perhaps this could be factored out?
module.exports = class LiveGetter
  constructor: ->
    @_urls = {}  # each url maps to "last_grabbed", "contents"
    @_currentTimeoutTime = null
    @_timeout = null

  get: (url, periodSecs=2) ->
    periodMillis = periodSecs * 1000
    now = Date.now()
    entry = @_urls[url]

    if not entry or entry.last_grabbed + periodMillis <= now
      @_urls[url] ||= {}
      @_urls[url].last_grabbed = now

      @_actuallyGet(url)

    if not @_timeout or now + periodMillis < @_currentTimeoutTime
      if @_timeout then window.clearTimeout(@_timeout)

      @_timeout = window.setTimeout(@_onTimeout.bind(@), periodMillis)
      @_currentTimeoutTime = now + periodMillis

    return @_urls[url].contents

  _actuallyGet: (url) ->
    request
      .get(url)
      # .withCredentials()
      .end (err, res) =>
        if !err and res.ok
          @_urls[url].contents = res.body
          Apparatus.refresh()
        else
          @_urls[url].contents = err
          Apparatus.refresh()

  _onTimeout: () ->
    @_timeout = null
    Apparatus.refresh()  # HACK: calling Apparatus seems funky here.
