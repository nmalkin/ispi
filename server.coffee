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
    console.log 'Opened new connection'
   
    # Client begins session
    socket.on 'begin', (name) ->
        console.log "#{name} initiated connection"

        # At this point, we start treating this connection as a full client.

        # Get the ID for this client, incrementing the field in the process.
        client.incr "ispi:next_user_id", (err, id) ->
            if err?
                console.log "ERROR: #{err}"
            else
                console.log "Client assigned id #{id}"

                # Remember the id for this user
                socket.set 'id', id

                # Save the user's information
                client.hmset "ispi:user:#{id}",  { id: id, name: name }

        # Send welcome message
        console.log 'Sending welcome message'
        socket.emit 'welcome', {}


    randint = (max) ->
        Math.floor(Math.random()*max)
                
    # Selects a random position and calls the callback with the coordinates
    randomPosition = (callback) ->
        x = randint 600
        y = randint 300

        callback x, y

    # Selects the next appropriate position based on the trial 
    # and calls the callback with its coordinates
    getNextPosition = (trial, callback) ->
        randomPosition callback

    # Starts the next trial by obtaining the next position
    # and notifying the client
    startNextTrial = (id) ->
        # Get the number of the next trial
        client.incr "ispi:client:#{id}:trial", (err, trial) ->
            # Get the next position of the target
            getNextPosition trial, (x, y) ->
                console.log "New trial with target at #{x}, #{y}"

                # Store the position of the target for this trial
                client.hmset "ispi:client:#{id}:trial:#{trial}", {x: x, y: y}

                # Tell client to start new trial with this position
                socket.emit 'trial', {targetX: x, targetY: y}

    # Client has initialized display frame
    socket.on 'initialization done', () ->
        console.log 'Initiating trial'
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
                console.log "#{elapsedTime}: client #{id} is at #{x},#{y}"

                # Store the information we received from the client (time and position)
                client.get "ispi:client:#{id}:trial", (err, trial) -> # need to get the trial number first
                    if not err?
                        client.rpush "ispi:client:#{id}:trial:#{trial}:track", "#{elapsedTime}:#{x}:#{y}"
        
    # Client reports reaching target
    socket.on 'success', (data) ->
        socket.get 'id', (err, id) ->
            if err?
                console.log err
            else
                console.log "client #{id} reports finding target after #{data.elapsed} milliseconds"

                # Update trial record with time elapsed
                client.get "ispi:client:#{id}:trial", (err, trial) ->
                    if not err?
                        client.hset "ispi:client:#{id}:trial:#{trial}", 'duration', data.elapsed

                # Start the next trial
                startNextTrial id

                
