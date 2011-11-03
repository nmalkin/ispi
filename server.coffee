# Establish server
connect = require 'connect'
server = connect.createServer()
server.use connect.favicon()
server.use connect.logger()
server.use connect.static __dirname
server.listen(80)

# Start listening for socket connections
io = require('socket.io').listen server 

# On a socket connection:
io.sockets.on 'connection', (socket) ->
    console.log 'Opened new connection'
   
    # Client begins session
    socket.on 'begin', (name) ->
        console.log "#{name} initiated connection"
        
        console.log 'Setting name'
        # Set the name for this connection
        socket.set 'name', name, () ->
            console.log 'Sending welcome message'
            # Send welcome message
            socket.emit 'welcome', {}

    # Client has initialized display frame
    socket.on 'initialization done', () ->
        console.log 'Initiating trial'
        # This means they're ready to start their first trial.
        socket.emit 'trial', {targetX: 400, targetY: 300}

    # Client has moved mouse
    socket.on 'move', (data) ->
        x = data.x
        y = data.y
        elapsedTime = data.elapsed

        socket.get 'name', (err, name) ->
            if err?
                console.log err
            else
                console.log "#{elapsedTime}: #{name} is at #{x},#{y}"

    # Client reports reaching target
    socket.on 'success', (data) ->
        socket.get 'name', (err, name) ->
            if err?
                console.log err
            else
                console.log "#{name} reports finding target after #{data.elapsed} milliseconds"

                randint = (max) ->
                    Math.floor(Math.random()*max)
                
                # Pick out a random location for the target
                x = randint 600
                y = randint 300

                console.log "New trial with target at #{x}, #{y}"

                socket.emit 'trial', {targetX: x, targetY: y}
