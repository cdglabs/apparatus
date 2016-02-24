Firebase = require "firebase"
FirebasePromises = require "../Util/FirebasePromises"
Q = require "q"


###
Manages Apparatus's use of Firebase for drawing storage.
###


module.exports = class FirebaseAccess
  constructor: ->
    # This actually establishes a connection to Firebase and checks the current
    # auth status, so don't make a FirebaseAccess unless you're cool with that.
    @ref = new Firebase("https://aprtus.firebaseio.com/")
    @authData = @ref.getAuth();

  # Returns a promise to go through a login process.
  loginPromise: ->
    options = {scope: "email"}
    return FirebasePromises.authWithOAuthPopupPromise(@ref, "google", options)
      .then (authData) =>
        # save auth data locally
        @authData = authData

        # save auth data to server
        userRef = @ref.child("users").child(@authData.uid)
        newUserData =
          date: Firebase.ServerValue.TIMESTAMP
          email: @authData.google.email
        return FirebasePromises.setPromise(userRef, newUserData)

  # Returns a promise to go through a login process, if the user isn't logged in
  # already.
  loginIfNecessaryPromise: ->
    if not @authData
      return @loginPromise()
    else
      return Q()  # simple success

  saveUserInformationPromise: ->
    @loginIfNecessaryPromise()

  # Given a JSON string of a drawing, returns a promise to save the drawing's
  # data and return the drawing key. Will go into a login process, if necessary.
  saveDrawingPromise: (drawing) ->
    @loginIfNecessaryPromise().then =>
      drawingsRef = @ref.child("drawings")
      newDrawingData =
        uid: @authData.uid
        date: Firebase.ServerValue.TIMESTAMP
        source: drawing
      return FirebasePromises.pushPromise(drawingsRef, newDrawingData)
        .then (newDrawingRef) -> newDrawingRef.key()

  # Given a drawing key, returns a promise to return the drawing's data block.
  loadDrawingPromise: (key) ->
    drawingRef = @ref.child("drawings").child(key)
    return FirebasePromises.getValuePromise(drawingRef)
      .then (drawingDataSnapshot) =>
        if not drawingDataSnapshot.exists()
          throw new DrawingNotFoundError()
        drawingData = drawingDataSnapshot.val()
        return drawingData


# The error that occurs when you try to load a drawing that doesn't exist.
FirebaseAccess.DrawingNotFoundError = class DrawingNotFoundError
