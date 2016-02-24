Firebase = require "firebase"
Q = require "q"


module.exports = FirebasePromises = {}


###
Simple non-Apparatus-specific promises for use with Firebase
###


# Like ref.authWithOAuthPopupPromise(provider, ..., options). Resolves to the
# auth data object if successful.
FirebasePromises.authWithOAuthPopupPromise = (ref, provider, options) ->
  deferred = Q.defer()

  # traditional onComplete API, but non-traditional placement of `options` argument
  onComplete = deferred.makeNodeResolver()

  ref.authWithOAuthPopup(provider, onComplete, options)

  return deferred.promise


# Like ref.once('value', ...). Resolves to the resulting data snapshot.
FirebasePromises.getValuePromise = (ref) ->
  deferred = Q.defer()

  successCallback = (dataSnapshot) ->
    deferred.resolve(dataSnapshot)
  failureCallback = (error) ->
    deferred.reject(error)

  ref.once('value', successCallback, failureCallback)

  return deferred.promise


# Like ref.push(value, ...). Resolves to the ref of the pushed node if the push
# is successful.
FirebasePromises.pushPromise = (ref, value) ->
  deferred = Q.defer()

  # NOTE: non-traditional onComplete API
  onComplete = (maybeError) ->
    if maybeError
      deferred.reject(maybeError)
    else
      deferred.resolve(pushedRef)

  pushedRef = ref.push(value, onComplete)

  return deferred.promise


# Like ref.set(value, ...). Resolves (to nothing) if the push is successful.
FirebasePromises.setPromise = (ref, value) ->
  deferred = Q.defer()

  # NOTE: non-traditional onComplete API
  onComplete = (maybeError) ->
    if maybeError
      deferred.reject(maybeError)
    else
      deferred.resolve()

  ref.set(value, onComplete)

  return deferred.promise
