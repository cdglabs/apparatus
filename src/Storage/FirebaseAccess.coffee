###
Manages Apparatus's use of Firebase for drawing storage.
###

# Firebase dependencies are vendored, since our build process isn't up to the
# challenge of `require`-ing the latest versions.


module.exports = class FirebaseAccess
  constructor: ->
    # This actually establishes a connection to Firebase and checks the current
    # auth status, so don't make a FirebaseAccess unless you're cool with that.
    firebaseConfig =
      apiKey: "AIzaSyDWB0KbsvGSwBgQsHGWwyFdw0Lh4fS9W8k"
      authDomain: "aprtus.firebaseapp.com"
      databaseURL: "https://aprtus.firebaseio.com"
      projectId: "firebase-aprtus"
      storageBucket: "firebase-aprtus.appspot.com"
      messagingSenderId: "54941881239"
      appId: "1:54941881239:web:8b931f3e87d44c000c6ad2"
    firebase.initializeApp(firebaseConfig)
    @ref = firebase.database().ref()
    firebase.auth().onAuthStateChanged (user) => @user = user

  # Returns a promise to go through a login process.
  loginPromise: ->
    provider = new firebase.auth.GoogleAuthProvider();
    provider.addScope("https://www.googleapis.com/auth/userinfo.email")
    return firebase.auth()
      .signInWithPopup(provider)
      .then (result) =>
        # save user locally
        @user = result.user

        # save user to server
        userRef = @ref.child("users").child(@user.uid)
        newUserData =
          date: firebase.database.ServerValue.TIMESTAMP
          email: @user.providerData[0].email
        return userRef.set(newUserData)

  # Returns a promise to go through a login process, if the user isn't logged in
  # already.
  loginIfNecessaryPromise: ->
    if not @user
      return @loginPromise()
    else
      return Promise.resolve()  # simple success

  saveUserInformationPromise: ->
    @loginIfNecessaryPromise()

  # Given a JSON string of a drawing, returns a promise to save the drawing's
  # data and return the drawing key. Will go into a login process, if necessary.
  saveDrawingPromise: (drawing) ->
    @loginIfNecessaryPromise().then =>
      drawingsRef = @ref.child("drawings")
      newDrawingData =
        uid: @user.uid
        date: firebase.database.ServerValue.TIMESTAMP
        source: drawing
      newKey = drawingsRef.push().key
      drawingsRef.child(newKey).set(newDrawingData)
        .then () -> newKey

  # Given a drawing key, returns a promise to return the drawing's data block.
  loadDrawingPromise: (key) ->
    drawingRef = @ref.child("drawings").child(key)

    return drawingRef.get()
      .then (drawingDataSnapshot) =>
        if not drawingDataSnapshot.exists()
          throw new DrawingNotFoundError(key)
        drawingData = drawingDataSnapshot.val()
        return drawingData


# The error that occurs when you try to load a drawing that doesn't exist.
FirebaseAccess.DrawingNotFoundError = class DrawingNotFoundError extends Error
  constructor: (key) ->
    @name = "DrawingNotFoundError"
    @message = "Drawing with key \"#{key}\" cannot be found in Firebase"
