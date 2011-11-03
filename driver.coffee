TARGET_COLOR = 'red'
TARGET_RADIUS = 40 # pixels

# Target is initially off-screen
TARGET_INITIAL_X = -100
TARGET_INITIAL_Y = -100

debug = (message) ->
    console.log message

spotlightMove = (e, positionCallback) ->
    spot = $('#spot')
    box = $('#frame')

    boxPosition = box.position()

    clientX = e.pageX - boxPosition.left
    clientY = e.pageY - boxPosition.top

    xm = clientX - box.width()
    ym = clientY - box.height()
    spot.css 'backgroundPosition', xm + 'px ' + ym + 'px'

    positionCallback clientX, clientY

# Moves the target (and its ghost) to the specified position
moveTarget = (target, ghost, newX, newY) ->
    if target? and ghost?
        b = target.getBBox()

        dx = newX - b.x
        dy = newY - b.y

        target.translate dx, dy
        ghost.translate dx, dy

        debug "Currently at #{b.x}, #{b.y}"
        debug "New position #{newX}, #{newY}"
        debug "Translating #{dx}, #{dy}"

runTrial = (target, ghost, targetX, targetY, socket) ->
    # Move the target to the location for this trial
    moveTarget target, ghost, targetX, targetY

    # record the time when the trial starts
    startTime = Date.now()

    # Turn on spotlight handling
    $('#frame').mousemove (eventObject) -> # When the user moves their mouse,
        # move the spotlight
        spotlightMove eventObject, (x,y) -> # then:
            # Find out how long has passed since the beginning of the trial
            elapsedTime = Date.now() - startTime # in milliseconds

            # Report the elapsed time and the new position to the server 
            socket.emit 'move', {x: x, y: y, elapsed: elapsedTime}

    # Do this when subject successfully reaches target
    mouseoverHandler = () ->
        # Prevent repeated fires of the callback
        ghost.unmouseover mouseoverHandler

        # Stop spotlight tracking
        $('#frame').unbind()

        debug 'Acquired target'
        #alert 'You found it!'
        
        # Find out how long has passed since the beginning of the trial
        elapsedTime = Date.now() - startTime # in milliseconds

        # Report success to socket
        socket.emit 'success', {elapsed: elapsedTime}

    ghost.mouseover mouseoverHandler


# Draw circle at desired location
drawCircle = (canvas, x, y, radius, color) ->
    circle = canvas.circle x, y, TARGET_RADIUS 
    circle.attr "fill", color
    circle.attr "stroke", color
    circle

initFrame = (frameWidth, frameHeight, onComplete) ->
    debug 'Initializing frame'
    debug 'Loading frame from file'

    # Load the frame for the experiment display
    $('#content').load 'spotlight.html', () ->
        debug 'Frame loaded'
        
        box = $('#frame')

        # Set the frame to the requested size
        box.css 'width', frameWidth
        box.css 'height', frameHeight

        debug 'Initializing paper, surface, and other Rafael stuff'
        # When loaded:

        # Initialize "paper" under spotlight
        paper = Raphael 'paper', box.width(), box.height()

        # Draw the target circle
        target = drawCircle paper, TARGET_INITIAL_X, TARGET_INITIAL_Y, TARGET_RADIUS, TARGET_COLOR

        # We would like to attach a mouseover event to the target
        # (so we know when people reach it),
        # but the target wouldn't receive it because the event would
        # be captured by the spotlight layer above it.
        # So we create a new element, the "ghost", that lives above the spotlight
        # and captures the needed mouseover event.
        surface = Raphael 'surface', box.width(), box.height() # note that #surface has z-index > spot > paper
        ghost = drawCircle surface, TARGET_INITIAL_X, TARGET_INITIAL_Y,TARGET_RADIUS, 'transparent'

        onComplete target, ghost


    
# Called when client is ready to begin
runSession = (name) ->
    # Open connection to server
    debug 'Opening connection to server'
    socket = io.connect '/'

    # Register with server, provide it with client's name
    socket.on 'connect', (data) ->
        debug 'Connection established, sending begin message'
        socket.emit 'begin', name

    # Confirmation of registering with the server:
    # the server will provide us with our id
    socket.on 'welcome', (data) ->
        debug 'Received welcome message from server'
        # Also received frame width and height

        # Load and initialize frame where the action takes place
        initFrame data.width, data.height, (target, ghost) ->
            debug 'Done initializing frame, listening for trial start'
            socket.emit 'initialization done'

            socket.on 'trial', (data) ->
                debug 'Beginning new trial'
                runTrial target, ghost, data.targetX, data.targetY, socket

$(document).ready () ->
    # Load welcome page
    $('#content').load 'welcome.html', () ->
        # When the user is ready to begin
        $('#begin').click () ->
            debug 'Session initiated by user'

            # Get the user's name
            name = $('#name').val()

            if name isnt ""
                # Unbind from welcome-screen handler
                $('#begin').unbind()

                # Initiate session with server
                runSession name
