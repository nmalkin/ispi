TARGET_COLOR = 'red'
TARGET_RADIUS = 40 # pixels
TARGET_OFFSCREEN_X = -100
TARGET_OFFSCREEN_Y = -100

START_BUTTON_OFFSCREEN_X = TARGET_OFFSCREEN_X
START_BUTTON_OFFSCREEN_Y = TARGET_OFFSCREEN_X 
START_BUTTON_WIDTH = 60
START_BUTTON_HEIGHT = 40
START_BUTTON_COLOR = 'blue'

SPOTLIGHT_OFFSCREEN_X = -100
SPOTLIGHT_OFFSCREEN_Y = -100


debug = (message) ->
    console.log message

showMessage = (message) ->
    $('#message').html message

setSpotlightPosition = (x, y) ->
    box = $('#frame')
    xm = x - box.width()
    ym = y - box.height()

    spot = $('#spot')
    spot.css 'backgroundPosition', xm + 'px ' + ym + 'px'

hideSpotlight = () ->
    setSpotlightPosition SPOTLIGHT_OFFSCREEN_X, SPOTLIGHT_OFFSCREEN_Y

spotlightMove = (e, positionCallback) ->
    box = $('#frame')
    boxPosition = box.position()
    clientX = e.pageX - boxPosition.left
    clientY = e.pageY - boxPosition.top

    setSpotlightPosition clientX, clientY

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

waitUntilStartPressed = (startButton, startX, startY, onComplete) ->
    debug 'Waiting until user presses start button'

    # Move button from waiting position to active position
    startButton.translate startX - START_BUTTON_OFFSCREEN_X,
        startY - START_BUTTON_OFFSCREEN_Y

    pressed = 0 # a semaphore, effectively

    # Do this when user presses start button:
    onStartPress = () ->
        pressed++
        debug "Start button pressed (#{pressed})"

        # Disable mousedown handler (attempts to prevent repeated calls)
        startButton.unmousedown onStartPress

        if pressed == 1
            # Move the button off-screen
            startButton.translate START_BUTTON_OFFSCREEN_X - startX,
                START_BUTTON_OFFSCREEN_Y - startY

            # Execute callback
            onComplete()

    # Wait for user to press button
    startButton.mousedown () ->
        onStartPress()


runTrial = (target, ghost, targetX, targetY, socket) ->
    debug "Starting trial with target at #{targetX}, #{targetY}"

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

    acquired = 0

    # Do this when subject successfully reaches target
    mouseoverHandler = () ->
        acquired++
        debug "Acquired target at #{targetX}, #{targetY} (#{acquired})"

        if acquired == 1
            # Prevent repeated fires of the callback
            ghost.unmouseover mouseoverHandler

            # Stop spotlight tracking
            $('#frame').unbind()

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

        # Move spotlight off-screen, to begin
        setSpotlightPosition SPOTLIGHT_OFFSCREEN_X, SPOTLIGHT_OFFSCREEN_Y

        debug 'Initializing paper, surface, and other Rafael stuff'
        # When loaded:

        # Initialize "paper" under spotlight
        paper = Raphael 'paper', box.width(), box.height()

        # Draw the target circle
        target = drawCircle paper, TARGET_OFFSCREEN_X, TARGET_OFFSCREEN_Y, TARGET_RADIUS, TARGET_COLOR

        # We would like to attach a mouseover event to the target
        # (so we know when people reach it),
        # but the target wouldn't receive it because the event would
        # be captured by the spotlight layer above it.
        # So we create a new element, the "ghost", that lives above the spotlight
        # and captures the needed mouseover event.
        surface = Raphael 'surface', box.width(), box.height() # note that #surface has z-index > spot > paper
        ghost = drawCircle surface, TARGET_OFFSCREEN_X, TARGET_OFFSCREEN_Y, TARGET_RADIUS, 'transparent'

        # Also draw the start button
        startButton = surface.rect START_BUTTON_OFFSCREEN_X, START_BUTTON_OFFSCREEN_Y, START_BUTTON_WIDTH, START_BUTTON_HEIGHT
        startButton.attr 'fill', START_BUTTON_COLOR
        startButton.attr 'stroke', START_BUTTON_COLOR

        onComplete target, ghost, startButton


    
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
        showMessage 'Welcome!'
        # Also received frame width and height

        # Load and initialize frame where the action takes place
        initFrame data.width, data.height, (target, ghost, startButton) ->
            debug 'Done initializing frame, listening for trial start'
            socket.emit 'initialization done'

            socket.on 'trial', (data) ->
                debug 'Received signal to begin new trial'

                rt = () ->
                    debug "Beginning trial #{data.trial}"
                    showMessage "Round #{data.trial}"
                    runTrial target, ghost, data.targetX, data.targetY, socket

                if data.showStartButton # Begin the new trial when the user presses the start button
                    hideSpotlight()

                    waitUntilStartPressed startButton, data.startButtonX, data.startButtonY, () ->
                        # Show spotlight again. It will be placed at the start position.
                        # TODO: the spotlight will not appear exactly where the user clicked,
                        # since the user may have clicked anywhere in the start button rectangle
                        setSpotlightPosition data.startButtonX, data.startButtonY

                        rt()
                else # Begin trial immediately
                    rt()

     # Display messages from the server
     socket.on 'message', (message) ->
         showMessage message

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
