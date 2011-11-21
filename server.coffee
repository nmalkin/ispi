# Generates a random integer from [0, max-1]
randint = (max) ->
    Math.floor(Math.random()*max)
                
# Settings/configurations
FRAME_WIDTH = 1280
FRAME_HEIGHT = 1024 

CENTER_X = FRAME_WIDTH / 2
CENTER_Y = FRAME_HEIGHT / 2

START_BUTTON_X = CENTER_X - 30
START_BUTTON_Y = CENTER_Y - 20

R = 40
D = 2 * R
W = CENTER_X

CONDITION_1_P1_X = CENTER_X - (W-D)/2 - R
CONDITION_1_P1_Y = CENTER_Y
CONDITION_1_P2_X = FRAME_WIDTH - R
CONDITION_1_P2_Y = CENTER_Y
CONDITION_2_P1_X = CENTER_X + (W-D)/2 + R
CONDITION_2_P1_Y = CENTER_Y
CONDITION_2_P2_X = R
CONDITION_2_P2_Y = CENTER_Y

PILOT_getCondition = () ->
    randint 2

PILOT_getPosition = (condition, callback) ->
    closer = randint 3
    debug "Using trial-\"condition\" #{closer}"
    # Closer is 0, 1, or 2. If 1, use closer of positions.

    if condition == 1
        if closer == 1
            x = CONDITION_1_P1_X
            y = CONDITION_1_P1_Y
        else if closer == 0 or closer == 2
            x = CONDITION_1_P2_X
            y = CONDITION_1_P2_Y
        else
            throw new Error("unrecognized value for closer (#{closer})")
    else if condition == 0
        if closer == 1
            x = CONDITION_2_P1_X
            y = CONDITION_2_P1_Y
        else if closer == 0 or closer == 2
            x = CONDITION_2_P2_X
            y = CONDITION_2_P2_Y
        else
            throw new Error("unrecognized value for closer (#{closer})")
    else
        throw new Error("unrecognized value for condition (#{condition})")

    callback x, y

getCondition = () ->
    PILOT_getCondition()


debug = (message) ->
    console.log message

# Establish server
connect = require 'connect'
server = connect.createServer()
server.use connect.favicon()
server.use connect.logger()
server.use connect.static __dirname
server.listen(80)

# Establish connection to database
redis = require 'redis'
client = redis.createClient()
client.on "error", (err) ->
    console.log "DB ERROR: #{err}"

# Start listening for socket connections
io = require('socket.io').listen server

# On a socket connection:
io.sockets.on 'connection', (socket) ->
    debug 'Opened new connection'
   
    # Client begins session
    socket.on 'begin', (name) ->
        debug "#{name} initiated connection"

        # At this point, we start treating this connection as a full client.

        # Determine which condition the client is in.
        condition = getCondition()
        debug "Subject assigned to condition #{condition}"

        # Get the ID for this client, incrementing the field in the process.
        client.incr "ispi:next_user_id", (err, id) ->
            if err?
                console.log "ERROR: #{err}"
            else
                debug "Client assigned id #{id}"

                # Remember the id for this user
                socket.set 'id', id

                # Save the user's information
                client.hmset "ispi:subject:#{id}",  { id: id, name: name, condition: condition }

        # Send welcome message
        debug 'Sending welcome message'
        socket.emit 'welcome', {width: FRAME_WIDTH, height: FRAME_HEIGHT}


    # Selects a random position and calls the callback with the coordinates
    randomPosition = (callback) ->
        x = randint FRAME_WIDTH
        y = randint FRAME_HEIGHT

        callback x, y

    # Selects the next appropriate position based on the trial 
    # and calls the callback with its coordinates
    getNextPosition = (condition, trial, callback) ->
        #randomPosition callback
        PILOT_getPosition condition, callback

    # Starts the next trial by obtaining the next position
    # and notifying the client
    startNextTrial = (id) ->
        # Get condition
        client.hget "ispi:subject:#{id}", 'condition', (err1, condition) ->
            # Get the number of the next trial
            client.incr "ispi:subject:#{id}:trial", (err2, trial) ->
                if not (err1? or err2?)
                    condition = parseInt condition
                    trial = parseInt trial

                    # Get the next position of the target
                    getNextPosition condition, trial, (x, y) ->
                        debug "Trial #{trial} with target at #{x}, #{y}"

                        # Store the position of the target for this trial
                        client.hmset "ispi:subject:#{id}:trial:#{trial}", {x: x, y: y, finished: 'false'}

                        # Tell client to start new trial with this position
                        socket.emit 'trial',
                            {
                                targetX: x,
                                targetY: y,
                                showStartButton: true,
                                startButtonX: START_BUTTON_X,
                                startButtonY: START_BUTTON_Y,
                                trial: trial
                            }

    # Client has initialized display frame
    socket.on 'initialization done', () ->
        debug 'Initiating trial'
        # This means they're ready to start their first trial.
        socket.get 'id', (err, id) ->
            if not err?
                startNextTrial id

    # Client has moved mouse
    socket.on 'move', (data) ->
        x = data.x
        y = data.y
        elapsedTime = data.elapsed

        socket.get 'id', (err, id) ->
            if err?
                console.log err
            else
                debug "#{elapsedTime}: client #{id} is at #{x},#{y}"

                # Store the information we received from the client (time and position)
                client.get "ispi:subject:#{id}:trial", (err, trial) -> # need to get the trial number first
                    if not err?
                        client.rpush "ispi:subject:#{id}:trial:#{trial}:track", "#{elapsedTime}:#{x}:#{y}"
        
    # Client reports reaching target
    socket.on 'success', (data) ->
        socket.get 'id', (err, id) ->
            if err?
                console.log err
            else
                debug "client #{id} reports finding target after #{data.elapsed} milliseconds"

                # Tell client how they did
                seconds = data.elapsed / 1000
                socket.emit 'message', "You found the target in #{seconds} seconds."

                # Update trial record with time elapsed
                client.get "ispi:subject:#{id}:trial", (err, trial) ->
                    if not err?
                        client.hmset "ispi:subject:#{id}:trial:#{trial}", 
                            'finished', 'true',
                            'duration', data.elapsed

                # Start the next trial
                startNextTrial id

                
